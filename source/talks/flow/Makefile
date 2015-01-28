
index.html: flow.markdown
	pandoc -t revealjs -s flow.markdown -o index.html \
		-V revealjs-url=https://cdnjs.cloudflare.com/ajax/libs/reveal.js/3.0.0 \
		--highlight-style=zenburn
	sed -i'' s/simple.css/black.css/ index.html
