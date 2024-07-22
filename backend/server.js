const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const cors = require('cors');
const multer = require('multer');
const { GridFsStorage } = require('multer-gridfs-storage');
const Grid = require('gridfs-stream');
const path = require('path');
const crypto = require('crypto');

const app = express();
const port = 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Mongo URI
const mongoURI = 'mongodb+srv://pracExam:exam@practicalexam.9ielixx.mongodb.net/?retryWrites=true&w=majority&appName=PracticalExam';

// Create mongo connection
mongoose.connect(mongoURI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
  serverSelectionTimeoutMS: 5000, // Timeout after 5s instead of 30s
  socketTimeoutMS: 45000, // Close sockets after 45 seconds of inactivity
}).catch(err => console.error(`MongoDB connection error: ${err.message}`));

const conn = mongoose.connection;
conn.once('open', () => {
  console.log('MongoDB connection established');

  // Init stream
  gfs = Grid(conn.db, mongoose.mongo);
  gfs.collection('uploads');
});

// Create storage engine
const storage = new GridFsStorage({
  url: mongoURI,
  file: (req, file) => {
    return new Promise((resolve, reject) => {
      crypto.randomBytes(16, (err, buf) => {
        if (err) {
          return reject(err);
        }
        const filename = buf.toString('hex') + path.extname(file.originalname);
        const fileInfo = {
          filename: filename,
          bucketName: 'uploads'
        };
        resolve(fileInfo);
      });
    });
  }
});

const upload = multer({ storage });

const userSchema = new mongoose.Schema({
  email: String,
  password: String,
  imageFilename: String, // Field to store the image filename
});

const User = mongoose.model('User', userSchema);

// Register
app.post('/register', async (req, res) => {
  const { email, password } = req.body;
  const user = new User({ email, password });
  await user.save();
  res.status(201).send({ message: 'User registered' });
});

// Login
app.post('/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    const user = await User.findOne({ email, password });
    if (user) {
      res.send({ message: 'Login successful', email, imageFilename: user.imageFilename });
    } else {
      res.status(401).send({ message: 'Invalid credentials' });
    }
  } catch (err) {
    res.status(500).send({ message: 'Server error', error: err.message });
  }
});

// Upload Image
app.post('/upload', upload.single('image'), async (req, res) => {
  try {
    const email = req.body.email;
    const user = await User.findOne({ email });
    if (user) {
      user.imageFilename = req.file.filename;
      await user.save();
      res.status(201).send({ file: req.file });
    } else {
      res.status(404).send({ message: 'User not found' });
    }
  } catch (err) {
    res.status(500).send({ message: 'Server error', error: err.message });
  }
});

// Get all files
app.get('/files', (req, res) => {
  gfs.files.find().toArray((err, files) => {
    if (err) {
      return res.status(500).json({ err: 'Error retrieving files' });
    }
    if (!files || files.length === 0) {
      return res.status(404).json({ err: 'No files exist' });
    }
    return res.json(files);
  });
});

// Get single file
app.get('/files/:filename', (req, res) => {
  gfs.files.findOne({ filename: req.params.filename }, (err, file) => {
    if (err) {
      return res.status(500).json({ err: 'Error retrieving file' });
    }
    if (!file) {
      return res.status(404).json({ err: 'No file exists' });
    }
    return res.json(file);
  });
});

// Get image
app.get('/image/:filename', (req, res) => {
  gfs.files.findOne({ filename: req.params.filename }, (err, file) => {
    if (err) {
      return res.status(500).json({ err: 'Error retrieving image' });
    }
    if (!file) {
      return res.status(404).json({ err: 'No file exists' });
    }

    // Check if image
    if (file.contentType === 'image/jpeg' || file.contentType === 'image/png') {
      // Read output to browser
      const readstream = gfs.createReadStream(file.filename);
      readstream.pipe(res);
    } else {
      res.status(404).json({ err: 'Not an image' });
    }
  });
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
