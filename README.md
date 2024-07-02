# Documentación del Código D para Conectar a SQL Server

Este documento proporciona una descripción detallada del código D que establece una conexión con una base de datos SQL Server, ejecuta una consulta SQL, y maneja errores.

## Descripción General

El código está diseñado para:
1. Establecer una conexión con una base de datos SQL Server usando ODBC.
2. Ejecutar una consulta SQL para obtener datos.
3. Imprimir la versión del DBMS y los resultados de la consulta.
4. Manejar errores y mostrar mensajes de error apropiados.

## Requisitos

- **ODBC Driver**: Asegúrate de que el driver de SQL Server esté instalado en tu sistema.
- **DMD Compiler**: Necesitas el compilador de D para compilar el código.

## Código

```d
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
