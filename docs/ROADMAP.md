# Roadmap — El Corral

Adónde va la plataforma. Este documento es la visión, no un compromiso de fechas.

---

## Dónde estamos hoy

Un prototipo funcional en un solo archivo HTML, sin servidor y sin cuentas. Los datos viven en el navegador de cada uno.

Sirve para lo que tiene que servir en esta etapa: que un criador lo abra, lo use con caballos de verdad y diga qué le falta. Todo lo que sigue depende de esa devolución.

**Lo que ya funciona:** ficha completa por caballo, corral visual, buscador, sanidad con vencimientos, movimientos, crías y pedigrí, temporadas con control de papeles para viajar, finanzas en doble moneda, y archivo histórico de los caballos que ya no están.

**Lo que lo limita:** los datos no se comparten entre dispositivos ni entre personas, y no hay lugar para videos.

---

## 1. La evolución en video — el corazón de la plataforma

Es la función que diferencia a El Corral de una planilla.

Un caballo de polo se hace a lo largo de años, y hoy ese proceso no queda registrado en ningún lado. Existe en la cabeza del petisero que lo domó y en videos sueltos perdidos en el teléfono de alguien. Cuando llega el momento de venderlo, o de decidir si sigue, esa historia no está.

**La idea:** cada caballo tiene una línea de tiempo en video. Cada pieza queda anclada a una edad y a un hito del proceso.

- **Potranca en el campo** — cómo se movía antes de que la tocaran
- **Primeros trabajos** — la doma, los primeros meses de trabajo
- **Taqueo** — la primera vez con el taco
- **Primer chukker** — el momento que todos esperan
- **Temporada tras temporada** — cómo evolucionó de verdad

Cada video guarda **la fecha, la edad exacta del caballo en ese momento y el hito**, así la línea de tiempo se arma sola y se puede comparar entre caballos: *"a esta edad, ¿cómo se movía Lucera comparada con su hija?"*.

**Por qué importa comercialmente:** un comprador que ve la evolución completa de una yegua —de dónde salió, quién la hizo, cómo progresó— está mirando algo que ningún vendedor le puede mostrar hoy. Es el argumento de venta que hoy no existe.

**Por qué importa para el criadero:** permite evaluar la crianza con evidencia, no de memoria. Qué línea genética produce caballos que se hacen rápido, qué petisero doma mejor, qué madre repite.

---

## 2. Ficha comercial compartible por link

Hoy, para vender o alquilar un caballo, se mandan fotos por WhatsApp y se cuenta el resto de palabra.

**La idea:** cada caballo puede tener una ficha pública, de solo lectura, en su propio link. Se la mandás a un comprador y él ve —sin instalar nada y sin cuenta— las fotos, la línea de tiempo en video, el pedigrí, el historial deportivo con premios, el puntaje físico y el precio pedido. Los costos y todo lo interno del establo nunca aparecen.

Detalles que la hacen útil:

- **Se prende y se apaga.** El caballo se vendió, apagás el link y deja de existir.
- **Cuenta las visitas.** Sabés si el comprador la abrió, y cuántas veces.
- **Sirve para alquiler de temporada**, no solo para venta.

---

## 3. Multiusuario con roles

Un establo de cien caballos no lo carga una persona sola. Hoy la plataforma asume un solo usuario en un solo dispositivo, y eso es lo primero que se rompe en el uso real.

**La idea:** cada criadero es una organización, y cada persona entra con su usuario y ve lo que le corresponde.

| Rol | Qué puede hacer |
|---|---|
| **Dueño** | Todo: valuaciones, costos, decisiones de venta, alta y baja de personas |
| **Petisero** | Cargar novedades del día, movimientos, fotos y videos de los caballos a su cargo. No ve la plata |
| **Veterinario** | Cargar diagnósticos, tratamientos, vacunas y estudios. No ve la plata |

La regla que ordena todo: **cada dato tiene un responsable**, y se carga desde el celular en el momento, parado al lado del caballo. Lo que se deja para después no se carga nunca.

Esto implica mover los datos del navegador a un servidor, con lo que además se resuelve solo el problema de hoy: todos ven lo mismo, desde cualquier dispositivo, y nada se pierde si se rompe una computadora.

---

## Más adelante

Ideas que aparecieron y todavía no tienen prioridad. Están anotadas para no perderlas.

- **Costo real por caballo por día**, calculado solo a partir de los gastos del establo prorrateados
- **Alertas al celular** por vencimientos de vacunas, Coggins y herrajes
- **Modo campo sin señal**, que sincroniza cuando vuelve la conexión
- **Reportes de temporada**: qué caballos jugaron cuánto y qué rindieron
- **Comparador de líneas genéticas**: qué madre produce los caballos que llegan más lejos
- **Exportación para el contador** al cierre del ejercicio

---

## Cómo se decide qué sigue

Por lo que digan los criadores que lo usan. Las ideas que entren por [Issues](https://github.com/Simonet46/el-corral/issues) mandan sobre esta lista: si algo de acá no le sirve a nadie, se cae, y si aparece algo que no está previsto y resuelve un dolor real de todos los días, pasa al principio.
