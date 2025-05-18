const jwt = require('jsonwebtoken');

const authMiddleware = (req, res, next) => {
  const authHeader = req.header('Authorization');
  if (!authHeader) {
    console.error('Authorization header is missing'); // Debug log
    return res.status(401).json({ message: 'Access denied. No token provided.' });
  }

  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET); // Decode the token
    console.log('Decoded token:', decoded); // Log decoded token
    req.user = decoded; // Attach decoded payload to req.user
    next();
  } catch (error) {
    console.error('Invalid token:', error); // Log invalid token
    res.status(400).json({ message: 'Invalid token.' });
  }
};

module.exports = authMiddleware;




