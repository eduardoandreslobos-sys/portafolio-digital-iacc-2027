# Portafolio Digital 2027

Herramienta web para que la Vicerrectoría de Ecosistemas Digitales de IACC priorice y gestione el portafolio digital 2027 con un método común. Está pensada para Product Owners, Project/Product Managers y PMO, en equipos que trabajan en ágil, en cascada o en forma híbrida.

## Qué hace

| Vista | Para qué sirve |
|---|---|
| **Portafolio** | Ranking por índice de prioridad (IP). Cada evaluador puntúa de 1 a 5 cuatro criterios ponderados y el esfuerzo. El comité ve el promedio y la dispersión, marca para conversar donde no hay consenso y fija el puntaje acordado. La línea de capacidad indica cuántas iniciativas caben en el año. |
| **Roadmap** | Iniciativas por área sobre el año, con hitos y flechas de dependencia. En rojo, las dependencias con conflicto. |
| **Tablero** | Kanban de entregables, tareas e hitos. Un ítem puede ser ejecutado por un agente IA (Claude Code, Codex, Copilot), pero siempre tiene una persona responsable. |
| **Métricas** | Primero los resultados clave (KR), después el flujo: trabajo en curso, bloqueos, ítems terminados y tiempo de ciclo. El uso de agentes IA aparece solo como contexto. |
| **Comité** | Registro de decisiones por sesión: tipo, fundamento e iniciativas involucradas. Las decisiones no se borran, se revocan con su motivo. Fijar un puntaje acordado deja un registro automático. Cada edición o revocación guarda la versión anterior en el historial de la decisión. |

Además:
- **Qué cambió:** en Métricas y Roadmap hay una franja con los cambios de los últimos 7, 14 o 30 días: ítems terminados o bloqueados, updates, decisiones e iniciativas nuevas. Cada hecho enlaza a su origen y cada persona puede descartarlo de su vista. En claude.ai, Claude puede resumirla en un borrador que cita cada afirmación.
- **Vistas por rol:** PO, PM y PMO ven sus pendientes priorizados y pueden filtrar las iniciativas donde tienen ese rol.
- **Todo cambio rápido o de IA es reversible:** la edición directa en la tabla y la descomposición propuesta por IA ofrecen "Deshacer". Los ítems creados por IA quedan marcados como "Borrador IA" hasta que alguien los revisa y guarda.

Cada iniciativa tiene ficha con roles (PO, PM, PMO y responsable único), una matriz de responsabilidades según el método, descomposición en épicas o fases, dependencias ("depende de" y "bloquea a"), resultados clave, updates de estado, decisiones y evaluación.

**IP = (Σ peso × puntaje ÷ Σ pesos) ÷ esfuerzo × 10**

La app detecta estos conflictos de dependencia:
- Fechas: la iniciativa empieza antes de que termine aquella de la que depende.
- Capacidad: depende de una iniciativa que quedó bajo la línea de capacidad o sin puntaje.
- Estado: depende de una iniciativa en pausa o fuera de curso.
- Ciclos: no permite crear dependencias circulares.

## Modos de funcionamiento

La misma fuente (`src/app.html`) funciona de tres maneras:

1. **En claude.ai (artifact).** Datos compartidos en vivo, identidad de la organización y asistencia de Claude: descomponer iniciativas, redactar updates y redactar actas.
2. **En GitHub Pages con Supabase.** Datos compartidos en vivo entre todas las personas que ingresan con su correo. La asistencia IA no está disponible en este modo.
3. **Modo local.** Si `config.js` está vacío, los datos se guardan solo en el navegador de cada persona. Sirve para probar.

## Puesta en marcha con Supabase

1. Crea un proyecto en [supabase.com](https://supabase.com). El plan gratuito alcanza para este uso.
2. En **SQL Editor**, ejecuta completo el archivo [`supabase/schema.sql`](supabase/schema.sql).
3. Opcional: para limitar el acceso a correos institucionales, ejecuta:
   ```sql
   insert into public.allowed_domains values ('iacc.cl');
   ```
4. En **Authentication → URL Configuration**, agrega la URL de GitHub Pages (por ejemplo `https://<usuario>.github.io/<repositorio>/`) como *Site URL* y como *Redirect URL*.
5. En **Project Settings → API**, copia la *Project URL* y la clave *anon public* en [`config.js`](config.js). Haz commit y push.
6. Ingresa una vez con tu correo y nómbrate administrador para poder editar el método de priorización:
   ```sql
   insert into public.admins (user_id) select id from auth.users where email = 'tu.correo@iacc.cl';
   ```

La clave `anon` es pública por diseño. La seguridad la dan las políticas RLS del esquema:
- Solo miembros autenticados leen y escriben.
- Cada persona escribe únicamente su propio voto.
- Solo los administradores cambian el método o borran decisiones.

## Desarrollo

```bash
node scripts/build.mjs
```

Ese comando regenera `index.html` (la versión para GitHub Pages) desde `src/app.html`. Edita siempre `src/app.html`, ejecuta el build y haz commit de ambos archivos.

No hay dependencias ni bundler. La única librería externa es `@supabase/supabase-js`, que se carga desde jsDelivr solo cuando `config.js` tiene valores.

### Modelo de datos

Hay una sola tabla `docs (collection, id, data jsonb)` con estas colecciones:

| Colección | Contenido |
|---|---|
| `initiatives` | Ficha, roles, resultados clave, puntaje acordado y dependencias (`deps: [{id, kind, note}]`) |
| `items` | Épicas o fases, entregables, tareas e hitos, con asignado (persona o agente) y responsable |
| `updates` | Updates de estado con su salud |
| `votes` | Un documento por evaluador, con sus puntajes por iniciativa |
| `decisions` | Decisiones del comité: fecha de sesión, tipo, fundamento, iniciativas y estado |
| `settings/method` | Pesos, áreas, capacidad y umbral de consenso |
