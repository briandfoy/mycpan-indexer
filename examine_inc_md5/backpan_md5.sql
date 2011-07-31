CREATE TABLE IF NOT EXISTS backpan_md5 (
	md5             text,
	filename        text,
	blib            int,
	bytesize        int,
	primary_package text,
	version         text,
	dist_file       text
	);
DELETE FROM backpan_md5;
.separator "|"
.import backpan_md5_import.txt backpan_md5
