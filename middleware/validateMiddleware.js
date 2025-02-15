const validateMiddleware = (schema) => {
    return (req, res, next) => {
      const { error } = schema.validate(req.body);
      if (error) {
        return res.status(400).json({ message: error.details[0].message });
      }
      next();
    };
  };

  const validateLogin = [
    check('email').isEmail().withMessage('Invalid email format'),
    check('password').notEmpty().withMessage('Password is required'),
  ];
  
  const validateProject = [
    check('title').notEmpty().withMessage('Title is required'),
    check('description').notEmpty().withMessage('Description is required'),
    check('deadline').isISO8601().withMessage('Invalid date format for deadline'),
  ];
  
  module.exports = { validateProject };
  
  module.exports = { validateLogin };
  
  
  module.exports = validateMiddleware;
  