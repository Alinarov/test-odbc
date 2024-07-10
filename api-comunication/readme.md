<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Documentación del Código D para Conectar a SQL Server</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 0;
            background-color: #f4f4f4;
            color: #333;
        }
        .container {
            max-width: 800px;
            margin: 20px auto;
            padding: 20px;
            background: #fff;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
        }
        h1, h2 {
            color: #007acc;
        }
        code {
            background: #272822;
            color: #f8f8f2;
            padding: 2px 4px;
            border-radius: 3px;
        }
        pre {
            background: #272822;
            color: #f8f8f2;
            padding: 10px;
            overflow-x: auto;
            border-radius: 3px;
        }
        .code-block {
            margin-bottom: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Documentación del Código D para Conectar a SQL Server</h1>
        <p>Este documento proporciona una descripción detallada del código D que establece una conexión con una base de datos SQL Server, ejecuta una consulta SQL, y maneja errores.</p>
        
        <h2>Descripción General</h2>
        <p>El código está diseñado para:</p>
        <ul>
            <li>Establecer una conexión con una base de datos SQL Server usando ODBC.</li>
            <li>Ejecutar una consulta SQL para obtener datos.</li>
            <li>Imprimir la versión del DBMS y los resultados de la consulta.</li>
            <li>Manejar errores y mostrar mensajes de error apropiados.</li>
        </ul>

        <h2>Requisitos</h2>
        <ul>
            <li><strong>ODBC Driver:</strong> Asegúrate de que el driver de SQL Server esté instalado en tu sistema.</li>
            <li><strong>DMD Compiler:</strong> Necesitas el compilador de D para compilar el código.</li>
        </ul>

        <h2>Código</h2>
        <div class="code-block">
            <pre><code>
import odbc.sql;
import odbc.sqlext;
import odbc.sqlucode;
import odbc.sqltypes;
import std.stdio;
import std.string : fromStringz, toStringz;

version(Windows) {
    string connectionString = "Driver={SQL Server};Server=DESKTOP-E09IF8K;Database=ControlEmpleados;Trusted_Connection=True;TrustServerCertificate=Yes;";
} else {
    string connectionString = "Driver={SQL Server};Server=DESKTOP-E09IF8K;Database=ControlEmpleados;Trusted_Connection=True;";
}

alias SQLLEN = int;  // Usamos `int` en lugar de `long` para SQLLEN

SQLHENV env = SQL_NULL_HENV;
SQLHDBC conn = SQL_NULL_HDBC;

int main(string[] argv) {
    SQLRETURN ret;

    // Allocate an environment handle
    ret = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &env);

    // Set the ODBC version environment attribute
    if (!SQL_SUCCEEDED(ret = SQLSetEnvAttr(env, SQL_ATTR_ODBC_VERSION, cast(SQLPOINTER*) SQL_OV_ODBC3, 0))) {
        stderr.writefln("Failed to set ODBC version, SQL return code: %d", ret);
        return 1;
    }

    // Allocate a connection handle
    SQLAllocHandle(SQL_HANDLE_DBC, env, &conn);

    // Set login timeout to 30 seconds
    SQLSetConnectAttr(conn, SQL_LOGIN_TIMEOUT, cast(SQLPOINTER) 30, 0);

    writefln("Connecting to db with: %s", connectionString);

    // Connect to the database
    if (SQL_SUCCEEDED(ret = SQLDriverConnect(conn, null, cast(char*) toStringz(connectionString), SQL_NTS, null, 0, null, SQL_DRIVER_NOPROMPT))) {
        SQLCHAR[256] dbms_ver;

        writeln("Connected");

        // Get the DBMS version
        SQLGetInfo(conn, SQL_DBMS_VER, cast(SQLPOINTER)dbms_ver, dbms_ver.sizeof, null);

        writefln(" - DBMS Version:\t%s", fromStringz(cast(char*) dbms_ver));

        // Execute SQL query
        SQLHSTMT stmt = SQL_NULL_HSTMT;
        SQLAllocHandle(SQL_HANDLE_STMT, conn, &stmt);

        string query = "select * from registro_empleados";
        ret = SQLExecDirect(stmt, cast(SQLCHAR*) toStringz(query), SQL_NTS);

        if (SQL_SUCCEEDED(ret)) {
            SQLSMALLINT columns;
            SQLNumResultCols(stmt, &columns);

            while (SQL_SUCCEEDED(ret = SQLFetch(stmt))) {
                for (SQLUSMALLINT i = 1; i <= columns; i++) {
                    SQLCHAR[512] buf;
                    SQLLEN indicator;
                    ret = SQLGetData(stmt, i, SQL_C_CHAR, cast(SQLPOINTER) buf.ptr, buf.length, &indicator);
                    if (SQL_SUCCEEDED(ret)) {
                        if (indicator == SQL_NULL_DATA) {
                            write("\tNULL");
                        } else {
                            write("\t", fromStringz(cast(char*) buf.ptr));
                        }
                    }
                }
                writeln();
            }
        } else {
            stderr.writefln("Failed to execute query. SQL return code: %d", ret);
            writeErrorMessage(stmt);
        }

        // Free the statement handle
        SQLFreeHandle(SQL_HANDLE_STMT, stmt);

        // Disconnect from db and free allocated handles
        SQLDisconnect(conn);
        SQLFreeHandle(SQL_HANDLE_DBC, conn);
        SQLFreeHandle(SQL_HANDLE_ENV, env);
    } else {
        stderr.writefln("Failed to connect to database. SQL return code: %d", ret);
        writeErrorMessage();
        return 1;
    }

    return 0;
}

// If a call to SQL returns -1 (SQL_ERROR) then this function can be called to get the error message
void writeErrorMessage(SQLHSTMT stmt = null) {
    SQLCHAR[6] sqlstate;
    SQLINTEGER nativeError;
    SQLCHAR[SQL_MAX_MESSAGE_LENGTH] messageText;
    SQLSMALLINT bufferLength = messageText.length;
    SQLSMALLINT textLength;

    SQLRETURN ret = SQLError(
        env,
        conn,
        stmt,
        &sqlstate[0],
        &nativeError,
        &messageText[0],
        bufferLength,
        &textLength
    );

    if (SQL_SUCCEEDED(ret)) {
        writefln("SQL State %s, Error %d : %s", fromStringz(cast(char*) sqlstate), nativeError, fromStringz(cast(char*) messageText));
    }
}
            </code></pre>
        </div>

        <h2>Explicación del Código</h2>
        <h3>1. Importación de Módulos</h3>
        <p>El código importa módulos necesarios para la conexión ODBC y la manipulación de datos:</p>
        <ul>
            <li><code>import odbc.sql;</code>: Proporciona las funcionalidades básicas de ODBC.</li>
            <li><code>import odbc.sqlext;</code>: Extensiones para funciones adicionales de ODBC.</li>
            <li><code>import odbc.sqlucode;</code>: Manejo de errores y códigos de estado de ODBC.</li>
            <li><code>import odbc.sqltypes;</code>: Tipos de datos SQL usados en ODBC.</li>
            <li><code>import std.stdio;</code>: Funciones de entrada/salida estándar.</li>
            <li><code>import std.string : fromStringz, toStringz;</code>: Funciones de conversión entre cadenas de caracteres.</li>
        </ul>

        <h3>2. Configuración de la Cadena de Conexión</h3>
        <p>Se configura la cadena de conexión dependiendo del sistema operativo:</p>
        <pre><code>
version(Windows) {
    string connectionString = "Driver={SQL Server};Server=DESKTOP-E09IF8K;Database=ControlEmpleados;Trusted_Connection=True;TrustServerCertificate=Yes;";
} else {
    string connectionString = "Driver={SQL Server};Server=DESKTOP-E09IF8K;Database=ControlEmpleados;Trusted_Connection=True;";
}
        </code></pre>
        
        <h3>3. Manejo de la Conexión y Consultas</h3>
        <p>Se definen funciones para conectar a la base de datos, ejecutar consultas y manejar errores:</p>
        <ul>
            <li><code>conectar():</code> Establece una conexión con la base de datos y configura los atributos necesarios.</li>
            <li><code>executeQuery(query):</code> Ejecuta una consulta SQL y muestra los resultados.</li>
            <li><code>writeErrorMessage(stmt):</code> Obtiene y muestra el mensaje de error si ocurre un fallo.</li>
        </ul>

        <h3>4. Manejo de Errores</h3>
        <p>La función <code>writeErrorMessage</code> se encarga de imprimir mensajes de error detallados:</p>
        <pre><code>
void writeErrorMessage(SQLHSTMT stmt = null) {
    SQLCHAR[6] sqlstate;
    SQLINTEGER nativeError;
    SQLCHAR[SQL_MAX_MESSAGE_LENGTH] messageText;
    SQLSMALLINT bufferLength = messageText.length;
    SQLSMALLINT textLength;

    SQLRETURN ret = SQLError(
        env,
        conn,
        stmt,
        &sqlstate[0],
        &nativeError,
        &messageText[0],
        bufferLength,
        &textLength
    );

    if (SQL_SUCCEEDED(ret)) {
        writefln("SQL State %s, Error %d : %s", fromStringz(cast(char*) sqlstate), nativeError, fromStringz(cast(char*) messageText));
    }
}
        </code></pre>
        
        <h2>Conclusión</h2>
        <p>Este código proporciona una base sólida para conectar una aplicación escrita en D a una base de datos SQL Server usando ODBC. Puedes adaptarlo para realizar consultas más complejas, manejar diferentes errores, y mejorar su funcionalidad según las necesidades de tu proyecto.</p>
    </div>
</body>
</html>
