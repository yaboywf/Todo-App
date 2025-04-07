const express = require("express");
const cors = require("cors");
const passport = require('passport');
const LocalStrategy = require('passport-local').Strategy;
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const session = require('express-session');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');
const { encrypt, decrypt, getKey, createIv, encryptImage, decryptImage } = require('./encryption');
require('dotenv').config();

const app = express();
const db = new sqlite3.Database('database.db', (err) => {
    if (err) {
        console.error(err.message);
    }

    db.run("PRAGMA foreign_keys = ON;", (err) => {
        if (err) {
            console.error('Could not enable foreign key support', err);
        } else {
            console.log('Foreign key support enabled');
        }
    });
});

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
            return res.json({ token });
        });
    })(req, res, next);
});

app.get("/api/check_session", authenticateToken, (req, res) => {
    return res.json({ valid: true, user: req.user });
})

app.get("/api/get_user_data", authenticateToken, (req, res) => {
    db.get('SELECT * FROM users WHERE id = ?;', [req.user.id], (err, user) => {
        if (err) return res.status(500).json({ error: err.message });
        if (!user) return res.status(404).json({ message: "User not found" });

        const decryptedImage = decryptImage(user.user_image, getKey(req.user.enteredPassword, user.password.split("$")[3]), Buffer.from(user.iv, 'hex'));
        const base64Image = decryptedImage.toString('base64');
        user.user_image = base64Image;
        return res.json(user);
    });
})

app.post("/api/logout", authenticateToken, (req, res) => {
    req.logout(err => {
        if (err) return res.status(500).json({ error: err.message });

        return res.json({ message: "Logout successful" });
    });
})

app.put("/api/update_user_data/username", authenticateToken, (req, res) => {
    const username = req.body?.username;
    db.run('UPDATE users SET username = ? WHERE id = ?;', [username, req.user.id], (err) => {
        if (err) return res.status(500).json({ error: err.message });
        if (this.changes === 0) return res.status(404).json({ message: "User not found" });

        return res.json({ message: "Username updated successfully" });
    })
})

app.put("/api/update_user_data/image", authenticateToken, async (req, res) => {
    const image = req.body?.image;
    const bufferImage = Buffer.from(image, 'base64');
 
    db.get('SELECT * FROM users WHERE id = ?;', [req.user.id], (err, user) => {
        if (err) return res.status(500).json({ error: err.message });
        if (!user) return res.status(404).json({ message: "User not found" });

        const encryptedImage = encryptImage(bufferImage, getKey(req.user.enteredPassword, user.password.split("$")[3]), Buffer.from(user.iv, 'hex'));

        db.run('UPDATE users SET user_image = ? WHERE id = ?;', [encryptedImage, req.user.id], (err) => {
            if (err) return res.status(500).json({ error: err.message });
            if (this.changes === 0) return res.status(404).json({ message: "User not found" });

            return res.json({ message: "Image updated successfully" });
        })
    })
})

app.get("/api/get_tasks", authenticateToken, async (req, res) => {
    try {
        const tasks = await new Promise((resolve, reject) => {
            db.all('SELECT t.*, password, iv FROM parent_task t JOIN users ON t.user_id = users.id WHERE t.user_id = ?;', [req.user.id], (err, tasks) => {
                if (err) return reject(err);
                resolve(tasks);
            });
        });

        if (!tasks || tasks.length === 0) return res.json({ tasks: "no tasks" });

        for (let task of tasks) {
            const encryptionKey = getKey(req.user.enteredPassword, task.password.split("$")[3]);
            const iv = Buffer.from(task.iv, 'hex')
            const decryptedTaskName = decrypt(task.task_name, encryptionKey, iv);
            const decryptedDueDate = task.due_date ? decrypt(task.due_date, encryptionKey, iv) : null;

            task.task_name = decryptedTaskName;
            task.due_date = decryptedDueDate;
            task.subtasks = {};
            task.completed = task.completed === 1;

            const subtasks = await getSubTasks(req.user.id, task);

            if (subtasks) {
                for (let subtask of subtasks) {
                    const decryptedSubtaskName = decrypt(subtask.task_name, encryptionKey, iv);
                    const decryptedDueDate = subtask.due_date ? decrypt(subtask.due_date, encryptionKey, iv) : null;

                    const key = subtask.task_name = decryptedSubtaskName;
                    subtask.due_date = decryptedDueDate;
                    subtask.completed = subtask.completed === 1;

                    delete subtask.parent_task_id;
                    delete subtask.user_id;
                    delete subtask.task_name;

                    task.subtasks[key] = subtask;
                };
            }

            delete task.user_id;
            delete task.password;
            delete task.iv;
        }

        return res.json(tasks);
    } catch (err) {
        return res.status(500).json({ error: err.message });
    }
})

async function getSubTasks(user, task) {
    return new Promise((resolve, reject) => {
        db.all('SELECT * FROM sub_task WHERE user_id = ? AND parent_task_id = ?;', [user, task.id], (err, subtasks) => {
            if (err) return reject(err);

            resolve(subtasks);       
        })
    });
}

app.post("/api/tasks/create", authenticateToken, async (req, res) => {
    const { parent_task, task_name, due_date } = req.body;
    const task_type = parent_task ? "sub" : "parent";

    if (!task_name) return res.status(400).json({ message: "Task name is required" });
    
    db.get('SELECT * FROM users WHERE id = ?;', [req.user.id], (err, user) => {
        if (err) return res.status(500).json({ error: err.message });
        if (!user) return res.status(404).json({ message: "User not found" });

        const encryptionKey = getKey(req.user.enteredPassword, user.password.split("$")[3]);
        const iv = Buffer.from(user.iv, 'hex');

        const encryptedTaskName = encrypt(task_name, encryptionKey, iv);
        const encryptedDueDate = due_date ? encrypt(due_date, encryptionKey, iv) : null;

        if (task_type.toLowerCase() === "parent") {
            db.run('INSERT INTO parent_task (user_id, task_name, due_date, completed) VALUES (?, ?, ?, 0);', [req.user.id, encryptedTaskName, encryptedDueDate], (err) => {
                if (err) return res.status(500).json({ error: err.message });

                return res.json({ message: "Task created successfully" });
            })
        } else if (task_type.toLowerCase() === "sub") {
            db.run('INSERT INTO sub_task (user_id, parent_task_id, task_name, due_date, completed) VALUES (?, ?, ?, ?, 0);', [req.user.id, parent_task, encryptedTaskName, encryptedDueDate], (err) => {
                if (err) return res.status(500).json({ error: err.message });

                return res.json({ message: "Task created successfully" });
            })
        }
    })
})

app.delete("/api/tasks/delete", authenticateToken, async (req, res) => {
    const { id, task_type } = req.body;

    if (!id) return res.status(400).json({ message: "Task ID is required" });
    if (!task_type) return res.status(400).json({ message: "Task type is required" });

    if (task_type.toLowerCase() === "parent") {
        db.run('DELETE FROM parent_task WHERE id = ?;', [id], (err) => {
            if (err) return res.status(500).json({ error: err.message });

            return res.json({ message: "Task deleted successfully" });
        })
    } else if (task_type.toLowerCase() === "sub") {
        db.run('DELETE FROM sub_task WHERE id = ?;', [id], (err) => {
            if (err) return res.status(500).json({ error: err.message });

            return res.json({ message: "Task deleted successfully" });
        })
    }
})

app.listen(3000, "192.168.0.189", (error) => {
    if (error) {
        console.error(error);
        return;
    }

    console.log("server is running");
})