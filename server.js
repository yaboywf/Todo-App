const express = require("express");
const cors = require("cors");
const passport = require('passport');
const LocalStrategy = require('passport-local').Strategy;
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const session = require('express-session');
const sqlite3 = require('sqlite3').verbose();
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
    db.get('SELECT * FROM users WHERE username = ?', [username], (err, user) => {
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

app.post('/api/authenticate', (req, res, next) => {
    passport.authenticate('local', (err, user, info) => {
        if (err)  return res.status(500).json({ error: err.message });
        if (!user) return res.status(401).json({ message: 'Authentication failed' });

        req.login(user, (err) => {
            if (err) return res.status(500).json({ error: err.message });
            const token = jwt.sign({ id: req.user.id }, process.env.SECRET_KEY, { expiresIn: '6h' });
            res.json({ token });
        });
    })(req, res, next);
});

app.listen(3000, "192.168.0.189", (error) => {
    if (error) {
        console.error(error);
        return;
    }

    console.log("server is running")
})