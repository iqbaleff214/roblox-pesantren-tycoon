--!strict

-- Bootstrap: require all controllers so their module-body event wiring runs.
-- Order matches dependency: Build before UI/Notif (which may read build state).

require(script.Controllers.BuildController)
