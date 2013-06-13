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
.import backpan_md5_internal.txt backpan_md5
DELETE FROM backpan_md5 WHERE filename LIKE 'inc/%';
CREATE INDEX idx_md5 ON backpan_md5(md5);
