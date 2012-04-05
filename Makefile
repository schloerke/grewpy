

clean:
	@ rm lib/*.js

test:
	@exec node_modules/nodeunit/bin/nodeunit tests/unit/all.js

compile:
	@exec coffee --compile --bare -o lib/ lib/coffee/*.coffee

watch-tests:
	@ coffee --compile --bare --watch tests/unit/*.coffee &

watch-lib:
	@ coffee --compile --bare --watch -o lib/ lib/coffee/*.coffee &



watch: watch-lib watch-tests


run-examples:
	@ echo '';echo '-- Simple';node examples/simple.js; echo '';echo '-- Medium'; node examples/medium.js; echo '';echo '-- File'; node examples/file_utilization.js; echo '';echo '-- Max'; node examples/max_utilization.js

