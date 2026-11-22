require('dotenv').config();
const mongoose = require('mongoose');

const MONGO_URI =
  process.env.MONGO_URI ||
  'mongodb+srv://ROHIT:ROHIT@cluster0.tea3tom.mongodb.net/krishiDB?appName=Cluster0';

const DB_STATUS = {
  DISCONNECTED: 'DISCONNECTED',
  CONNECTING: 'CONNECTING',
  CONNECTED: 'CONNECTED',
  RETRYING: 'RETRYING',
};

let currentStatus = DB_STATUS.DISCONNECTED;
let retryAttempt = 0;
const MAX_RETRY_DELAY_MS = 60000; // Cap backoff at 60 seconds
const INITIAL_RETRY_DELAY_MS = 5000;

function getDbStatus() {
  return currentStatus;
}

function isDbConnected() {
  return currentStatus === DB_STATUS.CONNECTED && mongoose.connection.readyState === 1;
}

async function connectDB() {
  currentStatus = retryAttempt === 0 ? DB_STATUS.CONNECTING : DB_STATUS.RETRYING;
  console.log(`[MongoDB] Attempting connection... (Status: ${currentStatus}, Attempt: ${retryAttempt + 1})`);

  try {
    await mongoose.connect(MONGO_URI, {
      serverSelectionTimeoutMS: 4000,
      socketTimeoutMS: 15000,
    });
    currentStatus = DB_STATUS.CONNECTED;
    retryAttempt = 0;
    console.log('✅ [MongoDB] Connected successfully');
  } catch (err) {
    currentStatus = DB_STATUS.DISCONNECTED;
    console.warn(`⚠️ [MongoDB] Connection unavailable: ${err.message}`);
    console.warn('ℹ️ [MongoDB] Running in standalone IoT mode. Core sensor, crop, and pump endpoints remain fully active.');

    // Controlled exponential backoff
    retryAttempt++;
    const delay = Math.min(INITIAL_RETRY_DELAY_MS * Math.pow(1.5, retryAttempt - 1), MAX_RETRY_DELAY_MS);
    console.log(`[MongoDB] Next reconnection attempt in ${(delay / 1000).toFixed(1)} seconds...`);
    setTimeout(connectDB, delay);
  }
}

// Connection event listeners
mongoose.connection.on('disconnected', () => {
  if (currentStatus === DB_STATUS.CONNECTED) {
    currentStatus = DB_STATUS.DISCONNECTED;
    console.warn('⚠️ [MongoDB] Connection lost. Triggering reconnection...');
    retryAttempt = 0;
    connectDB();
  }
});

module.exports = {
  connectDB,
  getDbStatus,
  isDbConnected,
  DB_STATUS,
};
