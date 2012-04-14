<?php

define("TEXT_CUT_OFF_SIZE", 500);

if(file_exists("/Users/chrism/Sites/phptools/autoload.php")) {
	require_once("/Users/chrism/Sites/phptools/autoload.php");
}

$createFileName = __DIR__ . "/sql/create.sql";
if(file_exists($createFileName)) {
	unlink($createFileName);
}

system("export PGPASSWORD='h4ck0m4h4\;'");

$fileArray = glob("db/*.txt");

foreach($fileArray as $file) {
	$readHandle = fopen($file, 'r');

	//an array to contain the names of the headers from the first row
	$headerNameArray = fgetcsv($readHandle, 0, '|');

	$columnArray = array();

	while($lineArray = fgetcsv($readHandle, 0, '|')) {

		foreach($lineArray as $key => $value) {
			$columnArray[$headerNameArray[$key]] = getColumnInfo($columnArray, $headerNameArray[$key], $value);

		}
	}

	$tableName = pathinfo($file, PATHINFO_FILENAME);

	$sql = makeCreateStatement($tableName, $columnArray, __DIR__ . "/$file", $headerNameArray);
	file_put_contents($createFileName, $sql, FILE_APPEND);
}

/**
 * Makes the create statement for the table
 *
 * @param $tableName String The name of the table to be created
 * @param $columnArray Array An array of the form
 * 	array(
 * 		columnName => array(
 * 			type => BIGINT,
 * 			length => 11,
 * 		),
 * 		columnName => array(
 * 			type => BIGINT,
 * 			length => 11,
 * 		),
 * @return $sql String The sql to create the table
 */
function makeCreateStatement($tableName, $columnArray, $fileName, $headerNameArray) {
	$tmpArray = array();

	$sql = "DROP TABLE IF EXISTS $tableName;\n";
	$sql .= "CREATE TABLE $tableName (\n";

//	//if there isn't an ID column, make one
//	if(empty($columnArray['ID'])) {
//		$columnArray['ID'] = array(
//			'type' => 'BIGINT',
//		);
//	}

	$tmpHeaderArray = array();
	foreach($headerNameArray as $headerName) {
		$tmpHeaderArray[] = "\"{$headerName}\"";
	}

	foreach($columnArray as $fieldName => $columnInfo) {
		$columnSql = "\t\"$fieldName\" ";

		if('ID' == $fieldName) {
			$columnSql .= $columnInfo['type'] . " PRIMARY KEY";
		} elseif('TEXT' == $columnInfo['type'] || 'BIGINT' == $columnInfo['type']) {
			$columnSql .= $columnInfo['type'];
		} elseif('VARCHAR' == $columnInfo['type']) {
			$columnSql .= "{$columnInfo['type']}({$columnInfo['maxLength']})";
		}

		$tmpArray[] = $columnSql;
	}

	$columnString = implode(", ", $tmpHeaderArray);
	$sql .= implode(",\n", $tmpArray);
	$sql .= "\n);\n";
	$sql .= "COPY \"{$tableName}\" ({$columnString}) FROM '{$fileName}' WITH CSV HEADER DELIMITER '|';";

	return $sql;
}


/**
 * @param $columnArray
 * @param $headerNameArray
 * @param $index
 */
function getColumnInfo($columnArray, $headerName, $value) {
	//if there's already values there then use those
	if(! empty($columnArray[$headerName])) {
		$columnInfo = $columnArray[$headerName];
	} else {
		$columnInfo = array(
			'maxLength' => 1,
			'type' => 'BIGINT',
		);
	}

	if($columnInfo['type'] == 'TEXT') {
		//DON'T DO ANYTHING HERE
	} elseif($columnInfo['maxLength'] >= TEXT_CUT_OFF_SIZE) {
		$columnInfo['type'] = 'TEXT';

	} elseif(strlen($value) > $columnInfo['maxLength']) {
		$columnInfo['maxLength'] = strlen($value);
	}

	if(! preg_match("/^[0-9]*$/", $value)) {
		$columnInfo['type'] = 'VARCHAR';
	}

	return $columnInfo;
}