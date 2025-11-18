# Project Overview

This is an Angular application for managing a laser printing business called ZenToner. It is a single-page application (SPA) that uses Supabase as its backend for data storage and authentication. The frontend is built with Angular, TypeScript, and styled with Tailwind CSS and DaisyUI.

## Key Technologies

*   **Frontend:**
    *   Angular
    *   TypeScript
    *   Tailwind CSS
    *   DaisyUI
*   **Backend:**
    *   Supabase

## Architecture

The application is structured as a single-page application with a clear separation of concerns. It uses a feature-based architecture, with each feature (e.g., customers, tickets, auth) having its own module. The application uses a centralized routing configuration with lazy loading for better performance.

The application interacts with the Supabase backend through a dedicated `SupabaseService`, which provides a Supabase client to the rest of the application.

## Building and Running

### Prerequisites

*   Node.js and bun
*   Angular CLI

### Installation

1.  Install dependencies:

    ```bash
    bun install
    ```

### Running the application

1.  Start the development server:

    ```bash
    bun start
    ```

    The application will be available at `http://localhost:4200/`.

### Building the application

1.  Build the application for production:

    ```bash
    bun run build
    ```

    The build artifacts will be stored in the `dist/zentoner/` directory.

### Testing the application

1.  Run the unit tests:

    ```bash
    bun test
    ```

### Linting the application

1.  Lint the application code:

    ```bash
    bun run lint
    ```

## Development Conventions

*   **Coding Style:** The project uses Prettier for code formatting and ESLint for linting.
*   **Testing:** The project uses Karma and Jasmine for unit testing.
*   **Commits:** The project does not have a formal commit message convention, but it is recommended to follow the Conventional Commits specification.
