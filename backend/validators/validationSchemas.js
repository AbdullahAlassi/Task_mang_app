const Joi = require('joi');
const { validationResult } = require('express-validator');

// Schema for project creation
const createProjectSchema = Joi.object({
  title: Joi.string().min(3).max(50).required(),
  description: Joi.string().min(5).max(500).required(),
  deadline: Joi.date().required(),
});

// Schema for team creation
const createTeamSchema = Joi.object({
  name: Joi.string().min(3).max(50).required(),
  description: Joi.string().max(500).optional(),
  parent: Joi.string().optional(),
  type: Joi.string().valid('department', 'project', 'functional', 'cross-functional').default('functional'),
  status: Joi.string().valid('active', 'inactive', 'archived').default('active'),
  department: Joi.string().optional(),
  members: Joi.array().items(
    Joi.object({
      user: Joi.string().required(),
      role: Joi.string().valid('team_lead', 'member').required(),
    })
  ).optional(),
});

// Function to create Joi validation middleware
const validateRequest = (schema) => (req, res, next) => {
  const { error } = schema.validate(req.body);
  if (error) {
    return res.status(400).json({ error: error.details.map((detail) => detail.message) });
  }
  next();
};

// Joi validation middleware for user registration
const validateRegistration = validateRequest(
  Joi.object({
    name: Joi.string().min(3).max(50).required(),
    email: Joi.string().email().required(),
    password: Joi.string().min(6).required(),
  })
);

// Joi validation middleware for user login
const validateLogin = validateRequest(
  Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().min(6).required(),
  })
);

// Middleware to handle validation errors (for express-validator)
function handleValidationErrors(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  next();
}

module.exports = {
  createProjectSchema,
  createTeamSchema,
  validateRegistration, // Now it's a function
  validateLogin, // Now it's a function
  handleValidationErrors,
  validateRequest,
};
