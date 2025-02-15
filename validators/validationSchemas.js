const Joi = require('joi');

const createProjectSchema = Joi.object({
  title: Joi.string().min(3).max(50).required(),
  description: Joi.string().min(5).max(500).required(),
  deadline: Joi.date().required(),
});

const createTeamSchema = Joi.object({
  name: Joi.string().min(3).max(50).required(),
  parent: Joi.string().optional(),
  members: Joi.array().items(
    Joi.object({
      user: Joi.string().required(),
      role: Joi.string().valid('team_lead', 'member').required(),
    })
  ).optional(),
});

module.exports = {
  createProjectSchema,
  createTeamSchema,
};
