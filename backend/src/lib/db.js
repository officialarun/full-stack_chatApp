import mongoose from "mongoose";

export const connectDB = async () => {
  try {
    let mongoURI = process.env.MONGODB_URI;

    if (!mongoURI) {
      const username = encodeURIComponent(process.env.MONGO_INITDB_ROOT_USERNAME);
      const password = encodeURIComponent(process.env.MONGO_INITDB_ROOT_PASSWORD);
      const host = process.env.MONGO_HOST || "mongodb";
      const port = process.env.MONGO_PORT || "27017";
      const db = process.env.MONGO_DB || "chat-app";

      mongoURI = `mongodb://${username}:${password}@${host}:${port}/${db}?authSource=admin`;
    }

    if (!mongoURI) {
      throw new Error("MongoDB connection configuration missing");
    }

    const conn = await mongoose.connect(mongoURI, {
      maxPoolSize: 10,
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 45000,
    });

    console.log(`MongoDB connected: ${conn.connection.host}`);

    // ✅ ADD EVENT LISTENERS HERE
    mongoose.connection.on("connected", () => {
      console.log("Mongoose connected");
    });

    mongoose.connection.on("error", (err) => {
      console.error("Mongoose error:", err);
    });

    mongoose.connection.on("disconnected", () => {
      console.log("Mongoose disconnected");
    });

  } catch (error) {
    console.error("MongoDB connection error:", error);
    process.exit(1);
  }
};