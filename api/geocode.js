const cache = new Map();
let lastRequest = 0;
module.exports = async (req, res) => {
  if (req.method !== 'GET') return res.status(405).json({error: 'Method not allowed'});
  const q = typeof req.query.q === 'string' ? req.query.q.trim() : '';
  if (q.length < 3 || q.length > 200) return res.status(400).json({error: 'Invalid address'});
  const cached = cache.get(q);
  if (cached && cached.expires > Date.now()) {
    res.setHeader('Cache-Control', 'public, s-maxage=3600');
    return res.status(200).json(cached.data);
  }
  // A low-volume launch: no autocomplete; map selection works without this provider.
  if (Date.now() - lastRequest < 1000) {
    res.setHeader('Retry-After', '2');
    return res.status(429).json({error: 'Try again shortly or select on the map'});
  }
  lastRequest = Date.now();
  const url = new URL('/api/', process.env.GEOCODING_ORIGIN || 'https://photon.komoot.io');
  url.search = new URLSearchParams({q, bbox: '25,22,36.9,31.7', limit: '5'}).toString();
  try {
    const upstream = await fetch(url, {headers: {'User-Agent': 'Tawsela/1.0 (https://github.com/gamal6507-ops/Tawsela)'}, signal: AbortSignal.timeout(8000)});
    if (!upstream.ok) throw new Error('Provider unavailable');
    const data = await upstream.json();
    if (!Array.isArray(data.features)) throw new Error('Invalid provider response');
    const result = {features: data.features.slice(0, 5)};
    if (cache.size >= 100) cache.delete(cache.keys().next().value);
    cache.set(q, {data: result, expires: Date.now() + 3600000});
    res.setHeader('Cache-Control', 'public, s-maxage=3600');
    return res.status(200).json(result);
  } catch (_) { return res.status(503).json({error: 'Select the location on the map'}); }
};
