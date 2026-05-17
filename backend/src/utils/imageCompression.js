const sharp = require('sharp');
const path = require('path');
const fs = require('fs');

/**
 * Compress and optimize an uploaded image file in-place.
 * Converts to JPEG (or WebP if input is WebP) with quality reduction and resizing.
 * 
 * @param {string} filePath - Absolute path to the uploaded image file
 * @param {object} options
 * @param {number} [options.maxWidth=1200] - Max width in pixels
 * @param {number} [options.maxHeight=1200] - Max height in pixels
 * @param {number} [options.quality=75] - JPEG/WebP quality (1-100)
 * @returns {Promise<string>} - Path to the compressed file (may have changed extension)
 */
async function compressImage(filePath, options = {}) {
  const {
    maxWidth = 1200,
    maxHeight = 1200,
    quality = 75,
  } = options;

  const ext = path.extname(filePath).toLowerCase();
  const isWebp = ext === '.webp';

  // Read and process with sharp
  let pipeline = sharp(filePath)
    .resize(maxWidth, maxHeight, {
      fit: 'inside',
      withoutEnlargement: true,
    });

  // Output format
  if (isWebp) {
    pipeline = pipeline.webp({ quality });
  } else {
    pipeline = pipeline.jpeg({ quality, mozjpeg: true });
  }

  // Write to a temp file, then replace original
  const dir = path.dirname(filePath);
  const basename = path.basename(filePath, ext);
  const outputExt = isWebp ? '.webp' : '.jpg';
  const outputPath = path.join(dir, `${basename}${outputExt}`);
  const tempPath = path.join(dir, `${basename}_tmp${outputExt}`);

  await pipeline.toFile(tempPath);

  // Remove original if different path
  if (filePath !== outputPath) {
    fs.rmSync(filePath, { force: true });
  } else {
    fs.rmSync(filePath, { force: true });
  }

  // Rename temp to final
  fs.renameSync(tempPath, outputPath);

  return outputPath;
}

/**
 * Compress a profile photo (smaller size, optimized for avatars)
 */
async function compressProfilePhoto(filePath) {
  return compressImage(filePath, { maxWidth: 512, maxHeight: 512, quality: 70 });
}

/**
 * Compress a banner image (wider, higher quality)
 */
async function compressBanner(filePath) {
  return compressImage(filePath, { maxWidth: 1200, maxHeight: 600, quality: 72 });
}

/**
 * Compress a general offer/logo image
 */
async function compressOfferImage(filePath) {
  return compressImage(filePath, { maxWidth: 800, maxHeight: 800, quality: 72 });
}

module.exports = {
  compressImage,
  compressProfilePhoto,
  compressBanner,
  compressOfferImage,
};
