const { check, validationResult} = require('express-validator');

// Joi validation middleware for user login
const validateLogin = [
  check('email').isEmail().withMessage('Invalid email format'),
  check('password').notEmpty().withMessage('Password is requried'),
];

// Middleware to handle validation errors
function handleValidationErrors(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  next();
}

module.exports = {
  validateLogin,
  handleValidationErrors,
};


  
  