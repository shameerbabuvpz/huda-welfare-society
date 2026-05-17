const fs = require('fs');
const path = require('path');

const uploadsRoot = process.env.UPLOADS_ROOT
  || process.env.RAILWAY_VOLUME_MOUNT_PATH
  || path.resolve(__dirname, '..', '..', 'uploads');

const profilePhotosDir = path.join(uploadsRoot, 'profile-photos');
const orgLogosDir = path.join(uploadsRoot, 'org-logos');

for (const dir of [uploadsRoot, profilePhotosDir, orgLogosDir]) {
  fs.mkdirSync(dir, { recursive: true });
}

function buildPublicUploadUrl(req, relativePath) {
  const normalizedPath = relativePath.replace(/^\/+/, '').split(path.sep).join('/');
  const explicitBase = process.env.PUBLIC_BASE_URL || process.env.APP_PUBLIC_URL;

  if (explicitBase) {
    return `${explicitBase.replace(/\/$/, '')}/${normalizedPath}`;
  }

  const forwardedProto = req.headers['x-forwarded-proto'];
  const protocol = typeof forwardedProto === 'string'
    ? forwardedProto.split(',')[0].trim()
    : req.protocol;

  return `${protocol}://${req.get('host')}/${normalizedPath}`;
}

function resolveManagedPhotoPath(photoUrl) {
  if (!photoUrl) return null;

  let pathname = photoUrl;
  try {
    pathname = new URL(photoUrl).pathname;
  } catch (_) {
    pathname = photoUrl;
  }

  const normalized = pathname.replace(/\\/g, '/');
  if (!normalized.startsWith('/uploads/profile-photos/')) return null;

  const relativePath = normalized.replace(/^\/uploads\//, '');
  return path.join(uploadsRoot, ...relativePath.split('/'));
}

function deleteManagedPhoto(photoUrl) {
  const absolutePath = resolveManagedPhotoPath(photoUrl);
  if (!absolutePath) return;

  fs.rm(absolutePath, { force: true }, () => {});
}

module.exports = {
  uploadsRoot,
  profilePhotosDir,
  orgLogosDir,
  buildPublicUploadUrl,
  deleteManagedPhoto,
};