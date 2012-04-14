<?php

define("TEXT_CUT_OFF_SIZE", 500);

$fileArray = glob("db/*.txt");

foreach($fileArray as $file) {
	$readHandle = fopen($file, 'r');

	//an array to contain the names of the headers from the first row
	$columnArray = fgetcsv($readHandle, 0, '|');

	$tableName = pathinfo($file, PATHINFO_FILENAME);

	$sql = makeCreateStatement($tableName, $columnArray, __DIR__ . "/$file");
	file_put_contents(__DIR__ . "/sql/{$tableName}_create.sql", $sql);
}

/**
 * Makes the create statement for the table
 *
 * @param $tableName String The name of the table to be created
 * @param $columnArray Array An array of the form
 * 	array(
 * 		columnName => array(
 * 			type => int,
 * 			length => 11,
 * 		),
 * 		columnName => array(
 * 			type => int,
 * 			length => 11,
 * 		),
 * @return $sql String The sql to create the table
 */
function makeCreateStatement($tableName, $columnArray, $fileName) {
	$tmpArray = array();


	$sql = "DROP TABLE IF EXISTS $tableName;\n";
	$sql .= "CREATE TABLE $tableName (\n";

	foreach($columnArray as $column) {
		//$column = preg_replace("/\s/", '_', strtolower($column));
		$tmpArray[] = "\t\"$column\" varchar(500)";
	}

	$sql .= implode(",\n", $tmpArray);

	$sql .= "\n);\n";

	$sql .= "COPY \"{$tableName}\" FROM '{$fileName}' WITH DELIMITER '|';";

	return $sql;
}