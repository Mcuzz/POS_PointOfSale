# POS Terrasita (`punto_venta`)

Sistema de Punto de Venta (POS) desarrollado en **Flutter** con soporte para **Web** y backend en **Supabase** (Auth + PostgreSQL).

---

## Tabla de contenidos

1. [Requisitos previos](#requisitos-previos)
2. [Instalación y uso con Dev Container](#instalación-y-uso-con-dev-container)
3. [Configurar credenciales de Supabase](#configurar-credenciales-de-supabase)
4. [Ejecutar el proyecto en Flutter Web](#ejecutar-el-proyecto-en-flutter-web)
5. [Migrar las tablas de Supabase a una cuenta nueva o servidor](#migrar-las-tablas-de-supabase-a-una-cuenta-nueva-o-servidor)
6. [Estructura del proyecto](#estructura-del-proyecto)

---

## Requisitos previos

Para trabajar con el Dev Container necesitas tener instalado en tu equipo:

- [Git](https://git-scm.com/)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Windows / macOS) o Docker Engine (Linux)
- [Visual Studio Code](https://code.visualstudio.com/)
- Extensión de VS Code: **Dev Containers** (`ms-vscode-remote.remote-containers`)

---

## Instalación y uso con Dev Container

El repositorio incluye la configuración completa en [`.devcontainer/devcontainer.json`](.devcontainer/devcontainer.json) y [`.devcontainer/Dockerfile`](.devcontainer/Dockerfile) con:

- Ubuntu 24.04 + dependencias de Flutter Web, Linux Desktop y SQLite FFI
- Flutter SDK (canal `stable`) preconfigurado con soporte Web y Linux
- Node.js 22.x y `firebase-tools` (para hosting/emuladores con `firebase.json`)
- Extensiones de Dart y Flutter (`Dart-Code.dart-code`, `Dart-Code.flutter`)
- Puertos reenviados automáticamente:
  - `8080`: Flutter Web Dev Server
  - `5000`: Firebase Hosting
  - `9005`: Firebase CLI Auth

### Pasos para levantar el Dev Container

1. **Clona el repositorio** y entra al directorio:
   ```bash
   git clone https://github.com/jovani420/POS-Terrasita.git
   cd POS-Terrasita
   ```

2. **Abre el proyecto en VS Code**:
   ```bash
   code .
   ```

3. **Inicia el Dev Container**:
   - Si VS Code muestra la notificación *"Folder contains a Dev Container configuration file"*, haz clic en **Reopen in Container**.
   - O abre la paleta de comandos (`Ctrl+Shift+P` / `Cmd+Shift+P`) y ejecuta:
     ```text
     Dev Containers: Reopen in Container
     ```

4. **Espera a que termine la construcción**:
   - La primera vez descargará la imagen y compilará el entorno de Flutter.
   - Al finalizar, el `postCreateCommand` ejecutará automáticamente:
     - Ajuste de permisos en `/home/vscode/.pub-cache`
     - Copia de `.env.example` a `.env` (si `.env` aún no existe)
     - `flutter pub get`

5. **Verifica la instalación** dentro de la terminal integrada del contenedor:
   ```bash
   flutter doctor
   ```

---

## Configurar credenciales de Supabase

La aplicación carga las variables de entorno desde el archivo `.env` en la raíz del proyecto (declarado en `pubspec.yaml` bajo `flutter.assets` y cargado en `lib/main.dart` mediante `flutter_dotenv`).

### 1. Obtener tus credenciales en Supabase

En tu proyecto de Supabase (nuevo o existente):

1. Ve a **Project Settings** → **API** (o **Data API** / **API Keys**).
2. Copia:
   - **Project URL** (`https://<tu-proyecto>.supabase.co`)
   - **anon / public key** (usa la llave pública `anon`, **nunca** la `service_role` en el frontend).

> Si usas un servidor **Supabase Self-Hosted**, usa la URL pública de tu gateway (Kong, por ejemplo `http://tu-servidor:8000` o `https://api.tudominio.com`) y el `ANON_KEY` definido en la configuración de tu servidor.

### 2. Configurar el archivo `.env`

Si `.env` no se creó automáticamente, créalo a partir de `.env.example`:

```bash
cp .env.example .env
```

Edita `.env` y coloca tus credenciales:

```env
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_KEY=tu_anon_public_key_aqui
```

> **Importante:**
> - El archivo `.env` está incluido en `.gitignore` para evitar subir credenciales al repositorio.
> - Como `.env` está registrado como asset en `pubspec.yaml`, **debe existir** antes de compilar o ejecutar la app; si modificas `.env` con la app corriendo, detén y vuelve a ejecutar `flutter run`.

### 3. Crear usuario para iniciar sesión

La pantalla de login (`lib/features/auth/providers/auth_repository.dart`) usa **Supabase Auth** (`signInWithPassword`).

1. En el panel de Supabase, ve a **Authentication** → **Users**.
2. Haz clic en **Add user** → **Create new user**.
3. Ingresa correo electrónico y contraseña (activa **Auto Confirm User** si no tienes SMTP configurado).

---

## Ejecutar el proyecto en Flutter Web

### Dentro del Dev Container (recomendado)

El contenedor no incluye un navegador gráfico, por lo que se levanta el servidor web de Flutter en el puerto `8080` (ya reenviado en `devcontainer.json`) para abrirlo en el navegador de tu equipo anfitrión:

```bash
flutter pub get
flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0
```

Luego abre en tu navegador local:

```text
http://localhost:8080
```

### En tu máquina local (si tienes Google Chrome instalado)

```bash
flutter pub get
flutter run -d chrome --web-port 8080
```

### Compilar para producción (Web)

Para generar los archivos estáticos en `build/web`:

```bash
flutter build web
```

### Previsualizar o desplegar con Firebase Hosting (opcional)

El repositorio incluye `firebase.json` (apuntando a `build/web`) y `.firebaserc`:

```bash
# Previsualizar localmente en el puerto 5000
firebase emulators:start --only hosting

# Desplegar a Firebase Hosting
firebase login --no-localhost
firebase deploy --only hosting
```

---

## Migrar las tablas de Supabase a una cuenta nueva o servidor

Actualmente la app consume 4 tablas en el esquema `public` de PostgreSQL/Supabase:

- `categories`: categorías de productos (`name` único)
- `products`: catálogo e inventario (`name`, `sku`, `category`, `price`, `stock`, `image_path`)
- `sales`: encabezado de ventas (`total`, `payment_method`, `user_id`, `created_at`)
- `sale_items`: detalle de artículos vendidos (`sale_id`, `product_id`, `quantity`, `unit_price`)

> Nota: `lib/core/database/database_helper.dart` corresponde al esquema inicial en SQLite local (que incluía una tabla `users`). En la versión conectada a Supabase, los usuarios se gestionan desde **Supabase Auth**, por lo que no necesitas crear la tabla `users`.

### Opción 1: Crear las tablas en una cuenta nueva o servidor limpio (SQL)

En el nuevo proyecto de Supabase ve a **SQL Editor** → **New query** (o conéctate por `psql` si es un servidor PostgreSQL / Supabase self-hosted) y ejecuta el siguiente script:

```sql
-- =========================================================
-- Esquema POS Terrasita para Supabase (PostgreSQL)
-- =========================================================

-- 1. Tabla de categorías
CREATE TABLE IF NOT EXISTS public.categories (
  id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);

-- Categorías iniciales por defecto
INSERT INTO public.categories (name)
VALUES
  ('Comida'),
  ('Bebidas'),
  ('Postres'),
  ('Otros')
ON CONFLICT (name) DO NOTHING;

-- 2. Tabla de productos
CREATE TABLE IF NOT EXISTS public.products (
  id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  name TEXT NOT NULL,
  sku TEXT,
  category TEXT NOT NULL,
  price DOUBLE PRECISION NOT NULL,
  stock INTEGER NOT NULL DEFAULT 0,
  image_path TEXT
);

ALTER TABLE public.products
ADD CONSTRAINT products_price_nonnegative CHECK (price >= 0);

ALTER TABLE public.products
ADD CONSTRAINT products_stock_nonnegative CHECK (stock >= 0);

-- 3. Tabla de ventas
CREATE TABLE IF NOT EXISTS public.sales (
  id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  total DOUBLE PRECISION NOT NULL,
  payment_method TEXT NOT NULL,
  user_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. Tabla de detalle de ventas
CREATE TABLE IF NOT EXISTS public.sale_items (
  id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  sale_id BIGINT NOT NULL REFERENCES public.sales (id) ON DELETE CASCADE,
  product_id BIGINT NOT NULL REFERENCES public.products (id),
  quantity INTEGER NOT NULL,
  unit_price DOUBLE PRECISION NOT NULL
);

-- =========================================================
-- Row Level Security (RLS)
-- La app exige iniciar sesión con Supabase Auth antes de
-- consultar o modificar estas tablas.
-- =========================================================

```sql
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sale_items ENABLE ROW LEVEL SECURITY;
```

> **Advertencia de seguridad:** Las siguientes políticas RLS son temporales y se utilizan únicamente para facilitar las pruebas. Permiten que cualquier usuario autenticado consulte, inserte, actualice y elimine registros en estas tablas. Antes de utilizar el sistema en producción, deben sustituirse por políticas que restrinjan el acceso según los roles y permisos de cada usuario. No despliegues esta configuración en un entorno productivo.

```sql
CREATE POLICY "Usuarios autenticados acceso total categories"
  ON public.categories FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuarios autenticados acceso total products"
  ON public.products FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuarios autenticados acceso total sales"
  ON public.sales FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuarios autenticados acceso total sale_items"
  ON public.sale_items FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);
```

### Opción 2: Migrar esquema y datos desde una cuenta/servidor existente

Si ya tienes registros en otra cuenta de Supabase o servidor y quieres copiarlos tal cual:

#### Con `pg_dump` y `psql` (recomendado)

1. Obtén la cadena de conexión PostgreSQL (**Connection String / URI**) de ambos proyectos en Supabase:
   **Project Settings** → **Database** → **Connection string** (usa el modo *Direct connection* o *Session pooler* para migraciones).

2. Exporta solo los datos (o esquema + datos) del proyecto origen:
   ```bash
   # Exportar esquema de public
   pg_dump "postgresql://postgres:<PASSWORD_ORIGEN>@<HOST_ORIGEN>:5432/postgres" \
     --schema=public --schema-only --no-owner --no-privileges -f schema_public.sql

   # Exportar datos de las tablas en formato INSERT
   pg_dump "postgresql://postgres:<PASSWORD_ORIGEN>@<HOST_ORIGEN>:5432/postgres" \
     --schema=public --data-only --column-inserts \
     -t public.categories -t public.products -t public.sales -t public.sale_items \
     -f data_public.sql
   ```

3. Importa en el nuevo proyecto o servidor destino:
   ```bash
   psql "postgresql://postgres:<PASSWORD_DESTINO>@<HOST_DESTINO>:5432/postgres" -f schema_public.sql
   psql "postgresql://postgres:<PASSWORD_DESTINO>@<HOST_DESTINO>:5432/postgres" -f data_public.sql
   ```

   > Si en el destino ya ejecutaste el SQL de la Opción 1, omite `schema_public.sql` y ejecuta únicamente `data_public.sql`.

4. **Sincroniza las secuencias de IDs** en el destino (evita errores de `duplicate key value` al crear nuevos registros tras importar IDs existentes):
   ```sql
   SELECT setval(pg_get_serial_sequence('public.categories', 'id'), COALESCE((SELECT MAX(id) FROM public.categories), 1), true);
   SELECT setval(pg_get_serial_sequence('public.products', 'id'),   COALESCE((SELECT MAX(id) FROM public.products), 1), true);
   SELECT setval(pg_get_serial_sequence('public.sales', 'id'),      COALESCE((SELECT MAX(id) FROM public.sales), 1), true);
   SELECT setval(pg_get_serial_sequence('public.sale_items', 'id'), COALESCE((SELECT MAX(id) FROM public.sale_items), 1), true);
   ```

#### Alternativa sin CLI (por CSV)

1. Primero crea las tablas en el nuevo proyecto con el SQL de la **Opción 1**.
2. En el proyecto origen, ve a **Table Editor**, selecciona cada tabla y expórtala como **CSV** en este orden:
   1. `categories`
   2. `products`
   3. `sales`
   4. `sale_items`
3. En el proyecto destino, importa cada CSV respetando el mismo orden (por las llaves foráneas de `sale_items`) y ejecuta al final el bloque de sincronización de secuencias (`setval`) mostrado arriba.

> **Importante sobre cuentas de usuario:** Los usuarios de **Authentication** (`auth.users`) no se migran con el esquema `public`. Debes recrearlos en **Authentication → Users** del nuevo proyecto y actualizar tu archivo `.env` con la nueva `SUPABASE_URL` y `SUPABASE_KEY`.

---

## Estructura del proyecto

```text
.
├── .devcontainer/
│   ├── devcontainer.json          # Configuración de VS Code Dev Container y puertos
│   └── Dockerfile                 # Imagen base con Flutter, Node.js y Firebase CLI
├── lib/
│   ├── core/database/
│   │   └── database_helper.dart   # Esquema SQLite local de referencia
│   ├── features/
│   │   ├── auth/                  # Login con Supabase Auth
│   │   ├── inventory/             # CRUD de productos y categorías
│   │   ├── pos/                   # Terminal de ventas y cobro
│   │   └── reports/               # Dashboard KPIs e historial de ventas
│   ├── shared/layouts/
│   │   └── main_layout.dart       # Navegación lateral principal
│   └── main.dart                  # Carga .env e inicializa Supabase
├── web/                           # Archivos de entrada para Flutter Web
├── .env.example                   # Plantilla de variables de entorno
├── firebase.json                  # Configuración de Firebase Hosting (build/web)
└── pubspec.yaml                   # Dependencias y assets (.env)
```
