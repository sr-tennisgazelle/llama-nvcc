refresh: llama_destroy_function llama_create_function

llama_precompile:
	@make -C ../bluerose set-llama

llama_create_function:
	@llama update-function --create --build=images/bluerose bluerose-daniel

llama_invoke:
	@echo "syntax is > llama invoke bluerose-daniel echo 'hi'"

llama_destroy_function:
	@aws lambda delete-function --function-name bluerose-daniel || exit 0;