#!/usr/bin/env dmd 
import std;
import comunicacion;

alias print = writeln;



void main(string[] argv) {
	
	
	comunicaicon comu = new comunicaicon();

	comu.conectar();

	string[][] res = comu.ejecutar_query("SELECT * FROM fecha");

	print(res);


	

	//foreach (fila; respuesta_SQL) {
	//    writeln(fila);
	//}

	//string fecha = get_fecha();
	//writeln("fecha de hoy: "~ fecha);
	//writeln("fecha a comparar"~to!string(respuesta_SQL[0]));
	//// Comparar cada fecha en la lista con la fecha actual
	//if ( fecha == respuesta_SQL[0][0]) {
	//    writeln("La fecha coincide: ", fecha);
		
	//} else {
	//    writeln("La fecha no coincide: ", fecha);
	//}
	



}