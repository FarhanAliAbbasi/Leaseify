🏢 Leaseify - Smart Property Management App

Leaseify is a robust, dual-role mobile application designed to streamline the relationship between Landlords and Tenants. Built with Flutter, it provides a seamless interface for property management, financial tracking, and maintenance request handling.

📱 Features

🔐 Authentication & Security

Role-Based Access Control: Distinct dashboards for Landlords and Tenants.

Secure Login: JWT (JSON Web Token) authentication.

Session Persistence: "Remember Me" functionality using secure local storage.

Auto-Logout: Handles token expiration (401 Unauthorized) gracefully.

🎩 Landlord Portal ("The Command Center")

Interactive Dashboard: Real-time KPIs for Occupancy Rates, Vacant Units, and Monthly Revenue.

Financial Analytics: Custom-built bar charts visualizing Rent Collection trends (Due vs. Paid) and revenue growth.

Property Management: View and manage property details, including occupancy status and amenities.

Maintenance Hub: Track tenant requests, filter by status (Pending, In Progress), and update ticket lifecycles.

👤 Tenant Portal ("The Home Hub")

Lease Overview: Instant access to active lease details, rent amount, and due dates.

Payment History: Detailed transaction logs with status indicators (Paid/Overdue) and digital receipts.

Maintenance Requests: Easy submission form for repairs with status tracking.

Profile Management: Manage contact details and emergency contacts.

🛠️ Tech Stack

Framework: Flutter (Dart)

Networking: http package for RESTful API communication.

State Management: setState with a Clean Architecture approach (Service-Repository pattern).

Local Storage: shared_preferences for session management.

Utilities: intl for date and currency formatting.

Backend: Connected to a Node.js/MongoDB backend (Hosted on Render).

📂 Project Structure

The project follows a scalable and maintainable folder structure:

lib/
├── main.dart               # Entry point and Route definitions
├── pages/                  # UI Screens
│   ├── login_page.dart
│   ├── home_page.dart      # Landing Page
│   ├── landlord_dashboard.dart
│   ├── tenant_dashboard.dart
│   ├── properties_page.dart
│   ├── financial_page.dart
│   ├── maintenance_page.dart
│   └── profile_page.dart
├── services/               # Logic & API Handling (Separation of Concerns)
│   ├── landlord_api_service.dart
│   └── tenant_api_service.dart
└── sections/               # Reusable Widgets for Landing Page
    ├── hero_section.dart
    ├── pricing_section.dart
    └── ...




🚀 Getting Started

Prerequisites

Flutter SDK installed.

An Android Emulator or iOS Simulator.

Installation

Clone the repository:

git clone [https://github.com/farhanaliabbasi/leaseify.git](https://github.com/farhanaliabbasi/leaseify.git)
cd leaseify


Install Dependencies:

flutter pub get


Run the App:

flutter run


💡 Key Implementation Details

Custom Charting: The financial bar charts and occupancy visualizations were built from scratch using Flutter's Row, Container, and Flex widgets, eliminating the need for heavy external charting libraries.

Robust Data Parsing: The service layer includes defensive coding to handle various API response formats (nested objects, missing keys, null values) to prevent app crashes.

🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

Fork the Project

Create your Feature Branch (git checkout -b feature/AmazingFeature)

Commit your Changes (git commit -m 'Add some AmazingFeature')

Push to the Branch (git push origin feature/AmazingFeature)

Open a Pull Request

📧 Contact

Your Name Full Stack Developer LinkedIn www.linkedin.com/in/farhanaliabbasi
