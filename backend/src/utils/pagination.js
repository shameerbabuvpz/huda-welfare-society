function paginate(query, { page = 1, limit = 20 }) {
  const p = Math.max(1, parseInt(page, 10));
  const l = Math.min(100, Math.max(1, parseInt(limit, 10)));
  const offset = (p - 1) * l;
  return { query: query.limit(l).offset(offset), page: p, limit: l, offset };
}

function paginationMeta(total, page, limit) {
  return {
    total,
    page,
    limit,
    totalPages: Math.ceil(total / limit),
  };
}

module.exports = { paginate, paginationMeta };
