import { parseArgs } from 'node:util';
import { provisionTenantAdmin } from './provision-tenant-admin.js';

const { values } = parseArgs({
  options: {
    'tenant-project-id': { type: 'string' },
    'organisation-id': { type: 'string' },
    'first-name': { type: 'string' },
    'last-name': { type: 'string' },
    email: { type: 'string' },
    phone: { type: 'string' },
  },
});

const result = await provisionTenantAdmin({
  tenantProjectId: values['tenant-project-id'] ?? '',
  organisationId: values['organisation-id'],
  firstName: values['first-name'] ?? '',
  lastName: values['last-name'] ?? '',
  email: values.email ?? '',
  phone: values.phone ?? '',
});

process.stdout.write(`${JSON.stringify(result, null, 2)}\n`);
process.exit(result.ok ? 0 : 1);
