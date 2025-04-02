const express = require("express");
const cors = require("cors");

const app = express();

app.use(cors({
    origin: "http://192.168.0.129:3000",
    methods: ["GET", "POST", "PUT", "DELETE"],
    credentials: true
}));
app.use(express.json())

app.post("/api/authenticate", (req, res) => {
    const { username, password } = req.body;
    
    console.log(username, password)
})

app.listen(3000, "192.168.0.129", (error) => {
    if (error) {
        console.error(error);
        return;
    }

    console.log("server is running")
})