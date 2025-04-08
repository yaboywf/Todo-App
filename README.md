# TODO App with Flutter, Dart, and Express.js

## Overview
This is a cross-platform TODO application built with:
- Frontend: Flutter (Dart) for mobile and web interfaces
- Backend: Express.js (Node.js) for the API server
- Database: SQLite

The app allows users to create, read, update, and delete tasks with additional features like task creation, due dates, and completion tracking.

## Features
### Frontend (Flutter)
- Decent Material Design UI
- Create, edit, and delete tasks
- Mark tasks as complete
- Ability to add Due dates

### Backend (Express.js)
- RESTful API endpoints
- User authentication (JWT)
- CRUD operations for tasks
- Data validation
- Database integration
- Error handling

## Prerequisites
1. Flutter SDK (latest stable version)
2. Dart SDK
3. Node.js
4. npm or yarn
5. SQLite3

## Installation
### Frontend (Flutter)
1. Clone the repository:
<br>
<code>git clone https://github.com/yaboywf/Todo-App.git</code>
<br>
<code>cd todo-app/flutter_app</code>

2. Install dependencies:
<br>
<code>flutter pub get</code>

3. Run the app:
<br>
<code>flutter run</code>

### Backend (Express.js)
1. Navigate to the backend directory:
<br>
<code>cd /path/to/directory</code>

2. Install dependencies:
<br>
<code>npm install</code>

OR

<code>yarn install</code>

3. Start the server:

<code>npm server.js</code>

## Configuration
### Frontend
1. Replace ALL existing IPv4 to the desired IP Address

### Backend
1. Replace ALL existing IPv4 to the desired IP Address
2. Add your own secret key

## API Endpoints
| Method	| Endpoint	| Description |
|-----------|-----------|--------------|
| POST	    | /api/authenticate	| Login user |
| GET	    | /api/check_session | Check whether the current user is authenticated |
| GET	    | /api/get_user_data | Get user information |
| POST	    | /api/logout | Log out the current user |
| PUT       | /api/update_user_data/username |Updates the user's username |
| PUT	    | /api/update_user_data/image |	Update the user's profile picture |
| GET       | /api/get_tasks | Get all tasks |
| POST      | /api/tasks/create | Create a new task |
| DELETE    | /api/tasks/delete | Delete a task |
| PUT       | /api/tasks/update/completed | Mark a task as completed / not completed |
| PUT       | /api/tasks/update/details | Update a task's details like task name or due date |
| POST      | /api/create_account | Create a new account |
| DELETE    | /api/delete_delete | Delete an existing account |

## Project Structure
<pre>
todo-app/
│
├── .dart_tool
├── .idea
├── .android
├── assets
|   ├── login_bg.jpg
|   ├── logo.png
│   └── profile_bg.webp
├── build
├── lib                             # Flutter frontend
│   ├── account.dart                # Creating an account page
│   ├── functions.dart              # General functions used in the app
|   ├── login.dart                  # Login page
│   ├── profile.dart                # Profile page
│   ├── tasks.dart                  # Tasks page
│   └── main.dart                   # Main entry into app
│
├── node_modules
├── .env
├── .flutter-plugins
├── .flutter-plugins-dependencies
├── .gitignore
├── .metadata
├── analysis_options.yaml
├── database.db                     # SQLite database used in the app
├── encryption.js                   # Handle encryption and decryption of data
├── package.json
├── package-lock.json
├── pubspec.lock
├── pubspec.yaml
├── server.js                       # Express.js backend
└── todo-_app.imi
</pre>

## Author
Dylan Yeo - yaboywf