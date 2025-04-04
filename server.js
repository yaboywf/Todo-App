const express = require("express");
const cors = require("cors");
const passport = require('passport');
const LocalStrategy = require('passport-local').Strategy;
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const session = require('express-session');
const sqlite3 = require('sqlite3').verbose();
const { encrypt, decrypt, getKey, createIv, encryptImage, decryptImage } = require('./encryption');
require('dotenv').config();

const app = express();
const db = new sqlite3.Database('database.db');

app.use(cors({
    origin: "http://0.0.0.0:3000",
    methods: ["GET", "POST", "PUT", "DELETE"],
    credentials: true
}));

app.use(express.json())
app.use(express.urlencoded({ extended: true }));

app.use(session({
    secret: process.env.SECRET_KEY,
    resave: false,
    saveUninitialized: true
}));

app.use(passport.initialize());
app.use(passport.session());

passport.use(new LocalStrategy((username, password, done) => {
    db.get('SELECT * FROM users WHERE username = ?', [username.trim()], (err, user) => {
        if (err) return done(err);
        if (!user) return done(null, false, { message: 'User not found' });

        bcrypt.compare(password, user.password, (err, isMatch) => {
            if (err) return done(err);
            if (!isMatch) return done(null, false, { message: 'Incorrect password' });
            return done(null, user);
        });
    });
}));

passport.serializeUser((user, done) => {
    done(null, user.id);
});

passport.deserializeUser((id, done) => {
    db.get('SELECT * FROM users WHERE id = ?', [id], (err, user) => {
        done(err, user);
    });
});

const authenticateToken = (req, res, next) => {
    let token = req.headers.authorization;
    if (!token) return res.status(401).json({ message: "Unauthorized" });
    token = token.split(" ")[1];
    
    jwt.verify(token, process.env.SECRET_KEY, (err, decoded) => {
        if (err) return res.status(403).json({ message: "Unauthorized" });
        req.user = decoded;
        next();
    });
};

app.post('/api/authenticate', (req, res, next) => {
    passport.authenticate('local', (err, user, info) => {
        if (err)  return res.status(500).json({ error: err.message });
        if (!user) return res.status(401).json({ message: info.message });

        req.login(user, (err) => {
            if (err) return res.status(500).json({ error: err.message });
            const token = jwt.sign({ id: req.user.id, enteredPassword: req.body.password }, process.env.SECRET_KEY, { expiresIn: '6h' });
            res.json({ token });
        });
    })(req, res, next);
});

app.get("/api/check_session", authenticateToken, (req, res) => {
    res.json({ valid: true, user: req.user });
})

app.get("/api/get_user_data", authenticateToken, (req, res) => {
    db.get('SELECT * FROM users WHERE id = ?;', [req.user.id], (err, user) => {
        if (err) return res.status(500).json({ error: err.message });
        if (!user) return res.status(404).json({ message: "User not found" });

        const decryptedImage = decryptImage(user.user_image, getKey(req.user.enteredPassword, user.password.split("$")[3]), Buffer.from(user.iv, 'hex'));
        const base64Image = decryptedImage.toString('base64');
        user.user_image = base64Image;
        res.json(user);
    });
})

app.post("/api/logout", authenticateToken, (req, res) => {
    req.logout(err => {
        if (err) return res.status(500).json({ error: err.message });

        res.json({ message: "Logout successful" });
    });
})

app.put("/api/update_user_data/username", authenticateToken, (req, res) => {
    const username = req.body?.username;
    db.run('UPDATE users SET username = ? WHERE id = ?;', [username, req.user.id], (err) => {
        if (err) return res.status(500).json({ error: err.message });
        if (this.changes === 0) return res.status(404).json({ message: "User not found" });

        res.json({ message: "Username updated successfully" });
    })
})

app.listen(3000, "192.168.0.189", (error) => {
    if (error) {
        console.error(error);
        return;
    }

    console.log("server is running");
})