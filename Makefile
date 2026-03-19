.PHONY: docker-up docker-pdf docker-clean docker-pdf-clean docker-help

DOCKER_IMAGE_NAME = latex-project

docker-help:
	@echo "LaTeX Docker Build System"
	@echo "========================"
	@echo ""
	@echo "Available commands:"
	@echo "  make docker-up		- Build the Docker image (run once)"
	@echo "  make docker-pdf		- Compile main LaTeX project to PDF"
	@echo "  make docker-clean		- Remove auxiliary files"
	@echo "  make docker-pdf-clean		- Compile PDF and clean auxiliary files"
	@echo "  make docker-help		- Show this help message"
	@echo ""
	@echo "Usage:"
	@echo "  1. make docker-up		# Build image once"
	@echo "  2. make docker-pdf		# Compile PDF"
	@echo ""

docker-up:
	@echo "Building Docker image: $(DOCKER_IMAGE_NAME)"
	docker build -t $(DOCKER_IMAGE_NAME) .
	@echo "✓ Docker image built successfully"

docker-pdf:
	@echo "Compiling LaTeX project..."
	docker run --rm \
		-v $$(pwd):/$$(basename $$(pwd)) \
		-w /$$(basename $$(pwd)) \
		$(DOCKER_IMAGE_NAME) \
		latexmk -pdf -interaction=nonstopmode main.tex
	@echo "✓ PDF compilation complete"
	@echo "Output: main.pdf"

docker-clean:
	@echo "Removing LaTeX auxiliary files..."
	rm -f *.aux *.log *.out *.toc *.fls *.fdb_latexmk
	rm -f *.synctex.gz *.bbl *.blg *.dvi *.ps *.spl
	@echo "✓ Auxiliary files cleaned"

docker-pdf-clean: docker-pdf docker-clean
	@echo "✓ Compiled and cleaned in one go!"