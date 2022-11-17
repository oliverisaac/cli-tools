testScript:
	docker run --entrypoint /bin/bash --workdir /data --mount type=bind,source=${PWD},target=/data ubuntu:latest .github/scripts/generate_formula.sh
