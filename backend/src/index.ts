import express from "express";
import { authRouter } from "./routes/auth";
import { progressRouter } from "./routes/progress";
import { iapRouter } from "./routes/iap";

const app = express();
app.use(express.json());

app.get("/health", (_req, res) => {
  res.json({ status: "ok" });
});

app.use("/auth", authRouter);
app.use("/progress", progressRouter);
app.use("/iap", iapRouter);

const port = process.env.PORT ? Number(process.env.PORT) : 3000;
app.listen(port, () => {
  console.log(`Coffee Break backend listening on port ${port}`);
});
