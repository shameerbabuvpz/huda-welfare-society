const path = require('path');
const bannerService = require('../services/banner.service');
const { buildPublicUploadUrl } = require('../config/uploads');
const { compressBanner } = require('../utils/imageCompression');

const bannerController = {
  async create(req, res, next) {
    try {
      const data = { ...req.body };
      if (req.file) {
        const compressedPath = await compressBanner(req.file.path);
        const compressedFilename = path.basename(compressedPath);
        data.image_url = buildPublicUploadUrl(req, `uploads/banners/${compressedFilename}`);
      }
      if (!data.image_url) {
        return res.status(400).json({ message: 'Banner image is required' });
      }
      const banner = await bannerService.create(req.organizationId, data, req.user.id);
      res.status(201).json(banner);
    } catch (err) { next(err); }
  },

  async list(req, res, next) {
    try {
      const banners = await bannerService.list(req.organizationId);
      res.json(banners);
    } catch (err) { next(err); }
  },

  async getById(req, res, next) {
    try {
      const banner = await bannerService.getById(req.organizationId, parseInt(req.params.id, 10));
      res.json(banner);
    } catch (err) { next(err); }
  },

  async update(req, res, next) {
    try {
      const data = { ...req.body };
      if (req.file) {
        const compressedPath = await compressBanner(req.file.path);
        const compressedFilename = path.basename(compressedPath);
        data.image_url = buildPublicUploadUrl(req, `uploads/banners/${compressedFilename}`);
      }
      const banner = await bannerService.update(req.organizationId, parseInt(req.params.id, 10), data, req.user.id);
      res.json(banner);
    } catch (err) { next(err); }
  },

  async delete(req, res, next) {
    try {
      await bannerService.delete(req.organizationId, parseInt(req.params.id, 10));
      res.json({ success: true });
    } catch (err) { next(err); }
  },

  // Member endpoint: active banners only
  async listActive(req, res, next) {
    try {
      const banners = await bannerService.listActive(req.organizationId);
      res.json(banners);
    } catch (err) { next(err); }
  },
};

module.exports = bannerController;
