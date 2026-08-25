import 'dart:convert';
import 'dart:typed_data';

import '../constants/import_constants.dart';
import '../sources/problem_source_extract_exception.dart';

class XlsParsedSheet {
  const XlsParsedSheet({required this.name, required this.matrix});

  final String name;
  final List<List<String>> matrix;
}

/// Reads legacy Excel 97-2003 (`.xls` / BIFF8) workbooks into string matrices.
abstract final class XlsSheetParser {
  XlsSheetParser._();

  static List<XlsParsedSheet> parse(List<int> bytes) {
    try {
      final _OleFile ole = _OleFile(Uint8List.fromList(bytes));
      final Uint8List? workbook = ole.stream('Workbook') ?? ole.stream('Book');
      if (workbook == null || workbook.isEmpty) {
        throw StateError('Workbook stream missing');
      }
      return _BiffWorkbook(workbook).sheets();
    } catch (e) {
      throw ProblemSourceExtractException('${ImportConstants.invalidExcelFileMessage} $e');
    }
  }
}

class _OleFile {
  _OleFile(this._bytes) {
    _data = ByteData.sublistView(_bytes);
    if (_bytes.length < 512) throw StateError('File too small');
    if (_data.getUint32(0, Endian.little) != 0xE011CFD0 ||
        _data.getUint32(4, Endian.little) != 0xE11AB1A1) {
      throw StateError('Not an OLE compound file');
    }
    _sectorSize = 1 << _data.getUint16(0x1E, Endian.little);
    _miniSectorSize = 1 << _data.getUint16(0x20, Endian.little);
    _miniCutoff = _data.getUint32(0x38, Endian.little);
    _fat = _loadFat();
    _entries = _loadDirectory();
    _miniFat = _loadMiniFat();
    _miniStream = _loadMiniStream();
  }

  final Uint8List _bytes;
  late final ByteData _data;
  late final int _sectorSize;
  late final int _miniSectorSize;
  late final int _miniCutoff;
  late final List<int> _fat;
  late final List<int> _miniFat;
  late final List<_OleEntry> _entries;
  late final Uint8List _miniStream;

  List<int> _loadFat() {
    final List<int> fatSectors = <int>[];
    for (var i = 0; i < 109; i++) {
      final int sec = _data.getInt32(0x4C + i * 4, Endian.little);
      if (sec >= 0) fatSectors.add(sec);
    }
    int next = _data.getInt32(0x44, Endian.little);
    final int extra = _data.getInt32(0x48, Endian.little);
    for (var n = 0; n < extra && next >= 0; n++) {
      final int at = _sectorOffset(next);
      final int slots = (_sectorSize ~/ 4) - 1;
      for (var i = 0; i < slots; i++) {
        final int sec = _data.getInt32(at + i * 4, Endian.little);
        if (sec >= 0) fatSectors.add(sec);
      }
      next = _data.getInt32(at + slots * 4, Endian.little);
    }

    final List<int> fat = <int>[];
    for (final int sector in fatSectors) {
      final int at = _sectorOffset(sector);
      for (var i = 0; i < _sectorSize ~/ 4; i++) {
        if (at + i * 4 + 4 > _bytes.length) break;
        fat.add(_data.getInt32(at + i * 4, Endian.little));
      }
    }
    return fat;
  }

  List<_OleEntry> _loadDirectory() {
    final int first = _data.getInt32(0x30, Endian.little);
    final Uint8List dir = _readFatChain(first);
    final List<_OleEntry> entries = <_OleEntry>[];
    for (var i = 0; i + 128 <= dir.length; i += 128) {
      final ByteData e = ByteData.sublistView(dir, i, i + 128);
      final int nameBytes = e.getUint16(64, Endian.little);
      if (nameBytes < 2) continue;
      final int chars = ((nameBytes ~/ 2) - 1).clamp(0, 31);
      final StringBuffer name = StringBuffer();
      for (var c = 0; c < chars; c++) {
        name.writeCharCode(e.getUint16(c * 2, Endian.little));
      }
      entries.add(
        _OleEntry(
          name: name.toString(),
          type: e.getUint8(66),
          startSector: e.getInt32(116, Endian.little),
          size: e.getInt32(120, Endian.little),
        ),
      );
    }
    return entries;
  }

  List<int> _loadMiniFat() {
    final int first = _data.getInt32(0x3C, Endian.little);
    final int count = _data.getInt32(0x40, Endian.little);
    if (first < 0 || count <= 0) return const <int>[];
    final Uint8List raw = _readFatChain(first, maxSectors: count);
    final ByteData view = ByteData.sublistView(raw);
    final List<int> fat = <int>[];
    for (var i = 0; i + 4 <= raw.length; i += 4) {
      fat.add(view.getInt32(i, Endian.little));
    }
    return fat;
  }

  Uint8List _loadMiniStream() {
    _OleEntry? root;
    for (final _OleEntry e in _entries) {
      if (e.type == 5) {
        root = e;
        break;
      }
    }
    if (root == null || root.startSector < 0 || root.size <= 0) {
      return Uint8List(0);
    }
    return _readFatChain(root.startSector, size: root.size);
  }

  int _sectorOffset(int sector) => 512 + sector * _sectorSize;

  Uint8List _readFatChain(int start, {int? size, int? maxSectors}) {
    final BytesBuilder out = BytesBuilder(copy: false);
    var sector = start;
    var hops = 0;
    final int limit = maxSectors ?? 200000;
    while (sector >= 0 && hops++ < limit) {
      final int at = _sectorOffset(sector);
      if (at + _sectorSize > _bytes.length) break;
      out.add(_bytes.sublist(at, at + _sectorSize));
      if (sector >= _fat.length) break;
      sector = _fat[sector];
    }
    final Uint8List raw = out.takeBytes();
    if (size != null && size >= 0 && size < raw.length) {
      return Uint8List.sublistView(raw, 0, size);
    }
    return raw;
  }

  Uint8List _readMiniChain(int start, int size) {
    final BytesBuilder out = BytesBuilder(copy: false);
    var sector = start;
    var hops = 0;
    while (sector >= 0 && hops++ < 200000) {
      final int at = sector * _miniSectorSize;
      if (at + _miniSectorSize > _miniStream.length) break;
      out.add(_miniStream.sublist(at, at + _miniSectorSize));
      if (sector >= _miniFat.length) break;
      sector = _miniFat[sector];
    }
    final Uint8List raw = out.takeBytes();
    if (size < raw.length) return Uint8List.sublistView(raw, 0, size);
    return raw;
  }

  Uint8List? stream(String name) {
    for (final _OleEntry entry in _entries) {
      if (entry.type != 2) continue;
      if (entry.name.toLowerCase() != name.toLowerCase()) continue;
      if (entry.size < _miniCutoff && _miniFat.isNotEmpty) {
        return _readMiniChain(entry.startSector, entry.size);
      }
      return _readFatChain(entry.startSector, size: entry.size);
    }
    return null;
  }
}

class _OleEntry {
  const _OleEntry({
    required this.name,
    required this.type,
    required this.startSector,
    required this.size,
  });

  final String name;
  final int type;
  final int startSector;
  final int size;
}

class _BiffWorkbook {
  _BiffWorkbook(this._bytes);

  final Uint8List _bytes;

  List<XlsParsedSheet> sheets() {
    final List<_SheetRef> refs = <_SheetRef>[];
    final List<String> sst = <String>[];
    var offset = 0;
    while (offset + 4 <= _bytes.length) {
      final int opcode = _u16(offset);
      final int length = _u16(offset + 2);
      final int start = offset + 4;
      if (start + length > _bytes.length) break;
      if (opcode == 0x00FC) {
        final BytesBuilder blob = BytesBuilder(copy: false);
        blob.add(_bytes.sublist(start, start + length));
        var next = start + length;
        while (next + 4 <= _bytes.length && _u16(next) == 0x003C) {
          final int clen = _u16(next + 2);
          final int cstart = next + 4;
          if (cstart + clen > _bytes.length) break;
          blob.add(_bytes.sublist(cstart, cstart + clen));
          next = cstart + clen;
        }
        sst.addAll(_parseSst(blob.takeBytes()));
      } else if (opcode == 0x0085) {
        refs.add(_readBoundSheet(start, length));
      }
      offset = start + length;
    }

    final List<XlsParsedSheet> tables = <XlsParsedSheet>[];
    for (final _SheetRef ref in refs) {
      if (ref.offset < 0 || ref.offset >= _bytes.length) continue;
      final Map<int, Map<int, String>> grid = _readSheet(ref.offset, sst);
      if (grid.isEmpty) continue;
      tables.add(XlsParsedSheet(name: ref.name, matrix: _gridToMatrix(grid)));
    }
    return tables;
  }

  _SheetRef _readBoundSheet(int start, int length) {
    final int sheetOffset = _u32(start);
    if (length < 8) return _SheetRef(offset: sheetOffset, name: 'Sheet');
    final int n = _bytes[start + 6];
    final int flag = _bytes[start + 7];
    final bool unicode = (flag & 0x01) != 0;
    final String name = unicode ? _unicode(start + 8, n) : _compressed(start + 8, n);
    return _SheetRef(offset: sheetOffset, name: name.trim().isEmpty ? 'Sheet' : name.trim());
  }

  List<String> _parseSst(Uint8List blob) {
    if (blob.length < 8) return const <String>[];
    final int unique = ByteData.sublistView(blob).getUint32(4, Endian.little);
    var pos = 8;
    final List<String> strings = <String>[];
    for (var i = 0; i < unique && pos + 3 <= blob.length; i++) {
      final int charCount = blob[pos] | (blob[pos + 1] << 8);
      pos += 2;
      if (pos >= blob.length) break;
      final int flags = blob[pos];
      pos += 1;
      var unicode = (flags & 0x01) != 0;
      final bool rich = (flags & 0x08) != 0;
      final bool asian = (flags & 0x04) != 0;
      var richCount = 0;
      if (rich) {
        if (pos + 2 > blob.length) break;
        richCount = blob[pos] | (blob[pos + 1] << 8);
        pos += 2;
      }
      if (asian) {
        if (pos + 4 > blob.length) break;
        pos += 4;
      }
      final StringBuffer text = StringBuffer();
      var left = charCount;
      while (left > 0 && pos < blob.length) {
        final int avail = unicode ? (blob.length - pos) ~/ 2 : (blob.length - pos);
        if (avail <= 0) break;
        final int take = left < avail ? left : avail;
        text.write(unicode ? _unicodeAt(blob, pos, take) : _compressedAt(blob, pos, take));
        pos += unicode ? take * 2 : take;
        left -= take;
      }
      pos += richCount * 4;
      strings.add(text.toString());
    }
    return strings;
  }

  Map<int, Map<int, String>> _readSheet(int start, List<String> sst) {
    final Map<int, Map<int, String>> grid = <int, Map<int, String>>{};
    var offset = start;
    var sawBof = false;
    while (offset + 4 <= _bytes.length) {
      final int opcode = _u16(offset);
      final int length = _u16(offset + 2);
      final int data = offset + 4;
      if (data + length > _bytes.length) break;
      if (opcode == 0x0809 || opcode == 0x0009) {
        if (sawBof) break;
        sawBof = true;
      } else if (opcode == 0x000A && sawBof) {
        break;
      } else if (sawBof) {
        final ({int row, int col, String text})? cell = _cell(opcode, data, length, sst);
        if (cell != null && cell.text.isNotEmpty) {
          grid.putIfAbsent(cell.row, () => <int, String>{})[cell.col] = cell.text;
        }
      }
      offset = data + length;
    }
    return grid;
  }

  ({int row, int col, String text})? _cell(int opcode, int data, int length, List<String> sst) {
    if (opcode == 0x00FD && length >= 10) {
      final int idx = _u32(data + 6);
      final String text = (idx >= 0 && idx < sst.length) ? sst[idx] : '';
      return (row: _u16(data), col: _u16(data + 2), text: text.trim());
    }
    if (opcode == 0x0204 && length >= 8) {
      final int n = _u16(data + 6);
      final int flag = length > 8 ? _bytes[data + 8] : 0;
      final String text = (flag & 0x01) != 0 ? _unicode(data + 9, n) : _compressed(data + 9, n);
      return (row: _u16(data), col: _u16(data + 2), text: text.trim());
    }
    if (opcode == 0x0203 && length >= 14) {
      final double n = ByteData.sublistView(_bytes, data + 6, data + 14).getFloat64(0, Endian.little);
      return (row: _u16(data), col: _u16(data + 2), text: _num(n));
    }
    if (opcode == 0x027E && length >= 10) {
      return (row: _u16(data), col: _u16(data + 2), text: _rk(_u32(data + 6)));
    }
    if (opcode == 0x0006 && length >= 14) {
      return (row: _u16(data), col: _u16(data + 2), text: _formulaValue(data + 6));
    }
    if (opcode == 0x0205 && length >= 8) {
      final String text = _bytes[data + 7] == 0 ? (_bytes[data + 6] == 1 ? 'true' : 'false') : '';
      return (row: _u16(data), col: _u16(data + 2), text: text);
    }
    return null;
  }

  String _formulaValue(int offset) {
    if (_bytes[offset + 6] != 0xFF || _bytes[offset + 7] != 0xFF) {
      return _num(ByteData.sublistView(_bytes, offset, offset + 8).getFloat64(0, Endian.little));
    }
    final int ident = _bytes[offset];
    if (ident == 1) return _bytes[offset + 2] == 1 ? 'true' : 'false';
    return '';
  }

  String _rk(int raw) {
    final bool div100 = (raw & 0x01) != 0;
    final bool isInt = (raw & 0x02) != 0;
    double n;
    if (isInt) {
      n = (raw >> 2).toSigned(30).toDouble();
    } else {
      final ByteData bd = ByteData(8);
      bd.setUint32(4, raw & 0xFFFFFFFC, Endian.little);
      n = bd.getFloat64(0, Endian.little);
    }
    if (div100) n /= 100;
    return _num(n);
  }

  String _num(double n) {
    if (n.isNaN || n.isInfinite) return '';
    if (n == n.roundToDouble()) return '${n.toInt()}';
    return '$n';
  }

  List<List<String>> _gridToMatrix(Map<int, Map<int, String>> grid) {
    final List<int> rows = grid.keys.toList()..sort();
    var maxCol = 0;
    for (final Map<int, String> cols in grid.values) {
      for (final int c in cols.keys) {
        if (c > maxCol) maxCol = c;
      }
    }
    final List<List<String>> matrix = <List<String>>[];
    for (final int r in rows) {
      final Map<int, String> cols = grid[r]!;
      final List<String> row = List<String>.filled(maxCol + 1, '');
      cols.forEach((int c, String v) {
        if (c >= 0 && c <= maxCol) row[c] = v;
      });
      if (row.any((String cell) => cell.trim().isNotEmpty)) matrix.add(row);
    }
    return matrix;
  }

  int _u16(int offset) => _bytes[offset] | (_bytes[offset + 1] << 8);

  int _u32(int offset) =>
      _bytes[offset] | (_bytes[offset + 1] << 8) | (_bytes[offset + 2] << 16) | (_bytes[offset + 3] << 24);

  String _compressed(int offset, int count) => _compressedAt(_bytes, offset, count);

  String _unicode(int offset, int count) => _unicodeAt(_bytes, offset, count);

  String _compressedAt(List<int> bytes, int offset, int count) {
    if (offset < 0 || count <= 0) return '';
    final int end = (offset + count < bytes.length) ? offset + count : bytes.length;
    return latin1.decode(bytes.sublist(offset, end), allowInvalid: true);
  }

  String _unicodeAt(List<int> bytes, int offset, int count) {
    if (offset < 0 || count <= 0) return '';
    final StringBuffer out = StringBuffer();
    for (var i = 0; i < count; i++) {
      final int at = offset + i * 2;
      if (at + 1 >= bytes.length) break;
      out.writeCharCode(bytes[at] | (bytes[at + 1] << 8));
    }
    return out.toString();
  }
}

class _SheetRef {
  const _SheetRef({required this.offset, required this.name});
  final int offset;
  final String name;
}
