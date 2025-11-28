"use strict";
const TodoController = require("./todoController");
module.exports = function (app, { tracer, redisClient, logChannel }) {
  const todoController = new TodoController({
    tracer,
    redisClient,
    logChannel,
  });

  // Health check endpoint
  app.get("/health", function (req, res) {
    // Check Redis connection
    redisClient.ping((err, result) => {
      if (err || result !== "PONG") {
        return res.status(503).json({
          status: "unhealthy",
          error: "Redis connection failed",
        });
      }

      res.json({
        status: "healthy",
      });
    });
  });

  app
    .route("/todos")
    .get(function (req, resp) {
      return todoController.list(req, resp);
    })
    .post(function (req, resp) {
      return todoController.create(req, resp);
    });

  app.route("/todos/:taskId").delete(function (req, resp) {
    return todoController.delete(req, resp);
  });
};
