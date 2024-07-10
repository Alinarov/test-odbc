#!/usr/bin/env dmd
module comunicacion;
import std;
import odbc.sql;
import odbc.sqlext;
import odbc.sqlucode;
import odbc.sqltypes;
import std.stdio;
import std.conv:to;
import std.string : fromStringz, toStringz;

alias print = writeln;

/**
 * comunicaicon
 */
 class comunicaicon {

	string connectionString = "Driver={SQL Server};Server=DESKTOP-E09IF8K;Database=prueba;Trusted_Connection=True;TrustServerCertificate=Yes;";
	alias SQLLEN = int;  // Usamos `int` en lugar de `long` para SQLLEN
	SQLHENV env = SQL_NULL_HENV;
	SQLHDBC conn = SQL_NULL_HDBC;
	
	SQLRETURN ret;

	this() {
	}

	void conectar () {
		// Allocate an environment handle
		ret = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &env);

		// Set the ODBC version environment attribute
		if (!SQL_SUCCEEDED(ret = SQLSetEnvAttr(env, SQL_ATTR_ODBC_VERSION, cast(SQLPOINTER*) SQL_OV_ODBC3, 0))) {
			stderr.writefln("Failed to set ODBC version, SQL return code: %d", ret);
			//return 1;
		}

		// Allocate a connection handle
		SQLAllocHandle(SQL_HANDLE_DBC, env, &conn);

		// Set login timeout to 3 seconds
		SQLSetConnectAttr(conn, SQL_LOGIN_TIMEOUT, cast(SQLPOINTER) 30, 0);

		writefln("[!] Me estoy conectando al servidor con este string: %s", connectionString);

	}

	string[][] ejecutar_query (string comando) {
		// Connect to the database
		if (SQL_SUCCEEDED(ret = SQLDriverConnect(conn, null, cast(char*) toStringz(connectionString), SQL_NTS, null, 0, null, SQL_DRIVER_NOPROMPT))) {
			SQLCHAR[256] dbms_ver;

			writeln("[+] Conectado");

			// Get the DBMS version
			SQLGetInfo(conn, SQL_DBMS_VER, cast(SQLPOINTER)dbms_ver, dbms_ver.sizeof, null);

			writefln(" - DBMS Version:\t%s", fromStringz(cast(char*) dbms_ver));

			// Execute SQL query
			SQLHSTMT stmt = SQL_NULL_HSTMT;
			SQLAllocHandle(SQL_HANDLE_STMT, conn, &stmt);

			//Aqui recibimos el comando sql o query sql ppara poder mandarlo al sqlserver para que lo ejecute
			string query = comando;


			ret = SQLExecDirect(stmt, cast(SQLCHAR*) toStringz(query), SQL_NTS);

			string[][] respuesta_SQL; // Cambiamos a un arreglo de arreglos de strings para almacenar filas completas

			if (SQL_SUCCEEDED(ret)) {
				// Si la ejecución de la consulta SQL fue exitosa, continuamos.            
				SQLSMALLINT columns;
				// Declaramos una variable para almacenar el número de columnas en el resultado de la consulta.
				SQLNumResultCols(stmt, &columns);
				// Obtenemos el número de columnas en el resultado de la consulta y lo almacenamos en 'columns'.
				while (SQL_SUCCEEDED(ret = SQLFetch(stmt))) {
					// Mientras la función SQLFetch retorne SQL_SUCCEEDED, continuamos iterando sobre las filas del resultado.
					// SQLFetch recupera una fila de datos del conjunto de resultados.
					string[] fila; // Arreglo temporal para almacenar los datos de la fila actual
					for (SQLUSMALLINT i = 1; i <= columns; i++) {
						// Iteramos sobre cada columna de la fila actual.
						SQLCHAR[512] buf;
						// Declaramos un buffer para almacenar los datos de la columna.
						SQLLEN indicator;
						// Declaramos una variable para almacenar el tamaño del dato recuperado o indicar si es NULL.
						ret = SQLGetData(stmt, i, SQL_C_CHAR, cast(SQLPOINTER) buf.ptr, buf.length, &indicator);
						// Obtenemos los datos de la columna 'i' de la fila actual.
						// Los datos se almacenan en el buffer 'buf' y 'indicator' se usa para verificar si los datos son NULL.
						if (SQL_SUCCEEDED(ret)) {
							// Si la obtención de datos fue exitosa, continuamos.
							if (indicator == SQL_NULL_DATA) {
								// Si el 'indicator' indica que el dato es NULL, agregamos "NULL" al arreglo temporal.
								fila ~= "NULL";
							} else {
								// Si el dato no es NULL, lo convertimos de una cadena C a una cadena D y lo agregamos al arreglo temporal.
								fila ~= to!string(fromStringz(cast(char*) buf.ptr));
							}
						}
					}
					respuesta_SQL ~= fila; // Agregamos la fila completa a la lista de respuestas
				}
			} else {
				// Si la ejecución de la consulta SQL falló, imprimimos un mensaje de error.
				stderr.writefln("Failed to execute query. SQL return code: %d", ret);
				
				writeErrorMessage(stmt);
				// Llamamos a la función writeErrorMessage para obtener y mostrar un mensaje de error detallado.
			}


			
			// Aqui solo desconectamos el handle osea el cursor que equivale en cursor.close() python
			SQLFreeHandle(SQL_HANDLE_STMT, stmt);


			return respuesta_SQL;


		} else {
			stderr.writefln("Failed to connect to database. SQL return code: %d", ret);
			writeErrorMessage();
		}
		return [["No se pudo conectar a la base de datos"]];
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

	void cerrar_conexion() {
		// Esta funcion no usar a no ser que sea necesario, cierra la conexion con el servidor
        SQLDisconnect(conn);
        SQLFreeHandle(SQL_HANDLE_DBC, conn);
        SQLFreeHandle(SQL_HANDLE_ENV, env);

	}

}