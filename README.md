![Flutter](https://img.shields.io/badge/Flutter-Mobile%20App-blue)
![Node.js](https://img.shields.io/badge/Node.js-Backend-green)
![Express](https://img.shields.io/badge/Express.js-API-lightgrey)
![MongoDB](https://img.shields.io/badge/MongoDB-Database-brightgreen)
![Dart](https://img.shields.io/badge/Dart-Language-blue)
![JWT](https://img.shields.io/badge/JWT-Authentication-orange)
![REST-API](https://img.shields.io/badge/REST-API-blueviolet)
![Status](https://img.shields.io/badge/Status-Active-success)
![License](https://img.shields.io/badge/License-MIT-yellow)

# ✅ Task Management App

A full-stack **task & project management** application with:

- 📱 **Flutter** mobile frontend  
- 🧠 **Node.js / Express** backend  
- 🗄️ **MongoDB** database  

Manage projects, boards, tasks, teams, and calendar events in one place.

---

## 🚀 Overview

This app helps teams and individuals:

- Create and manage **projects**
- Organize work into **boards & tasks**
- Collaborate with **teams**
- View deadlines in a **calendar**
- Receive **notifications** for important updates

The system uses **JWT-based authentication**, a **REST API** built with Node.js/Express, and a **Flutter** client using `provider` for state management.

---

## 🏗️ Architecture

          📱 Flutter App (frontend)
                    │
            REST API over HTTP
                    │
        🧠 Node.js / Express (backend)
                    │
            🗄️ MongoDB (Mongoose)

---

Backend routes (examples):

/api/auth – login, register, token-based auth

/api/users – user management

/api/projects – create & manage projects

/api/boards – boards/Kanban columns per project

/api/tasks – tasks under boards/projects

/api/teams – teams & members

/api/calendar – calendar-related items (deadlines, events)

/api/notifications – notifications for users

/api/project-teams – assignment of teams to projects


---

## 🧰 Tech Stack

| Layer        | Technology                                                                 |
|-------------|-----------------------------------------------------------------------------|
| Frontend    | Flutter, Provider, HTTP/Dio, Shared Preferences, Syncfusion Calendar        |
| Backend     | Node.js, Express.js, Socket.io (prepared), Express Validator, Joi           |
| Database    | MongoDB + Mongoose                                                          |
| Auth        | JWT (JSON Web Tokens), bcrypt/bcryptjs                                      |
| Others      | Multer (file uploads), CORS, dotenv, Jest + Supertest (for API tests)      |

---

## 📁 Project Structure

task-management-app/
│
├── backend/
│   ├── routes/          # Route definitions (auth, projects, tasks, etc.)
│   ├── models/          # Mongoose models
│   ├── middleware/      # Error handling, auth middleware
│   ├── app.js           # Express app entry
│   ├── db.js            # MongoDB connection
│   ├── package.json
│   └── .env.example     # Environment variables template (to create)
│
└── frontend/
    ├── lib/
    │   ├── screens/     # UI screens (auth, dashboard, projects, calendar, ...)
    │   ├── models/
    │   ├── providers/   # AuthProvider and other state logic
    │   ├── config/      # Themes, constants, API config
    │   └── main.dart
    ├── assets/
    ├── pubspec.yaml
    └── analysis_options.yaml

---

🔧 Backend Setup (Node.js)

1️⃣ Requirements
 Node.js (v18+ recommended)
 MongoDB instance (local or Atlas)

2️⃣ Install dependencies
 cd backend
 npm install

3️⃣ Configure environment variables
 Create a .env file inside backend/:

 PORT=3000
 MONGO_URI=your-mongodb-uri
 JWT_SECRET=your-secret-key

 You can also add other config values as needed (e.g. CORS origin, socket settings).

4️⃣ Run the backend
 # Development (with nodemon)
 npm run dev

 # Or normal start
 npm start

 The server will start at:
 http://localhost:3000 (or the PORT you set).

📱 Frontend Setup (Flutter)

1️⃣ Requirements
 Flutter SDK (3.x)
 Android Studio / VS Code with Flutter plugins

2️⃣ Install dependencies
 cd frontend
 flutter pub get
 
3️⃣ Configure API base URL
 Inside your Flutter project (e.g. in a config file like lib/config/api_config.dart), set your backend URL:

 const String apiBaseUrl = 'http://10.0.2.2:3000'; // Android emulator
 // or 'http://localhost:3000' when using web/desktop
 
4️⃣ Run the app
 flutter run
 
 Select a device/emulator and the app should start with the Splash → Login/Register → Dashboard flow.

✨ Core Features (Planned/Implemented)
 ☑️  User authentication (login/register with JWT)

 ☑️  Projects CRUD

 ☑️  Boards & tasks per project

 ☑️  Calendar view for tasks/events

 ☑️  Teams and project-team assignments

 🔳 Real-time updates with Socket.io

 🔳 Push notifications

 🔳 Attachments & file previews

🤝 Contributing
 1. Fork this repository
    
 2. Create a new feature branch:
  git checkout -b feature/your-feature-name
 
 3. Commit your changes:
  git commit -m "Add your message"
 
 4. Push the branch:
  git push origin feature/your-feature-name

 5. Open a Pull Request

---

📜 License
This project is currently shared for learning/portfolio purposes.
You can add an explicit license (MIT, Apache-2.0, etc.) here later.

---

📞 Contact
For questions or collaboration:

Email: abdullah.alassi123@gmail.com
GitHub: AbdullahAlassi
