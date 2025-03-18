const errorMiddleware = (err, req, res, next) => {
    console.error('Error:', err); // Log the error
  
    const statusCode = err.statusCode || 500;
    const message = err.message || 'Internal Server Error';
  
    res.status(statusCode).json({ error: message });
  };
  
  module.exports = errorMiddleware;
  