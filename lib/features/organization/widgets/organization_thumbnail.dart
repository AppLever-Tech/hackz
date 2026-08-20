import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/inputs/network_image_compat.dart';
import '../models/enums/organization_type.dart';
import '../models/organization_model.dart';

/// Rounded organisation icon used in lists and cards.
class OrganizationThumbnail extends StatelessWidget {
  const OrganizationThumbnail({
    super.key,
    required this.organization,
    this.size = 40,
  });

  final OrganizationModel organization;
  final double size;

  @override
  Widget build(BuildContext context) {
    final String url = organization.avatarUrl;
    final OrganizationType type = organization.type;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F0FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECF8)),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? Icon(
              AppIcons.forOrganizationType(type),
              size: size * 0.55,
              color: const Color(0xFF6A38FF),
            )
          : NetworkImageCompat(
              url: url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              logTag: 'OrganizationThumbnail',
              errorBuilder: (_) => Icon(
                AppIcons.forOrganizationType(type),
                size: size * 0.55,
                color: const Color(0xFF6A38FF),
              ),
            ),
    );
  }
}
