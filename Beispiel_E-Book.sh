#!/bin/bash
## Create ebook 'Beispiel E-Book'

# create pdf
pdffile="Beispiel E-Book"
pdftexfile="${pdffile}.tex"
rm *.aux *.pdf *.log *.toc
pdflatex "${pdftexfile}" && pdflatex "${pdftexfile}" && pdflatex "${pdftexfile}"

# reduce jpg image file size 
7z a jpg.7z images/*.jpg
mogrify -resize 66% -quality 52 images/*.jpg

# tex -> html, css
htmfile="Beispiel_E-Book"
rm *.dvi *.idv *.css *.4tc *.4ct *.aux *.lg *.xref *.html *.log *.tmp
htlatex ${htmfile}.tex ../ebook.cfg

# optimize htlatex created png files (equations)
optipng ${htmfile}*.png

# Optimize css, html
cp ${htmfile}.html ${htmfile}.orig.html
cp ${htmfile}.css ${htmfile}.orig.css
htmlclean ${htmfile}.html
python /usr/share/pyshared/slimmer/slimmer.py ${htmfile}.css --output=${htmfile}.css

# optimize css, html 
# ectt-0900 console set bold
sed -i 's/.ectt-0900{font-size:90%;font-family:monospace}/.ectt-0900{font-size:90%;font-family:monospace;font-weight:bold}/g' ${htmfile}.css
# ectt-0800 consolesmall set bold
sed -i 's/.ectt-0800{font-size:80%;font-family:monospace}/.ectt-0800{font-size:80%;font-family:monospace;font-weight:bold}/g' ${htmfile}.css
# lstlisting remove <br \>
sed -i -e ':a' -e 'N' -e '$!ba' -e 's/<pre><span\nclass=\"ectt-0800x-x-87\">&#x00A0;<\/span><br \/>/<pre>/g' ${htmfile}.html
sed -i -e ':a' -e 'N' -e '$!ba' -e 's/<pre class=listings><span\nclass=\"ectt-0800x-x-87\">&#x00A0;<\/span><br \/>/<pre class=listings>/g' ${htmfile}.html

# check http links
linklint ${htmfile}.html -warn -net > ${htmfile}.links.txt 2>/dev/null 

# create epub
ebook-convert ${htmfile}.html ${htmfile}.epub --input-encoding=iso-8859-1 --read-metadata-from-opf=${htmfile}.opf --language=de-DE

# png image to jpg or gif image
cd images
while read IMG_FILE; do
	echo convert ${IMG_FILE} from png to jpg quality 52...
	convert -quality 52 ${IMG_FILE}.png ${IMG_FILE}.jpg
	sed -i "s/${IMG_FILE}\.png\" alt=\"PIC\"/${IMG_FILE}\.jpg\" alt=\"PIC\"/g" ../${htmfile}.html
done<png2jpg.list

for file in *.png; do apng2gif "$file" "$(basename $file .png).gif"; done
sed -i 's/\.png\" alt=\"PIC\"/\.gif\" alt=\"PIC\"/g' ../${htmfile}.html
cd ..

# create mobi
archs=`uname -m`
case "$archs" in
    i?86) kindlegen -c2 ${htmfile}.html ;;
    x86_64) kindlegen -c2 ${htmfile}.html ;;
    *) qemu-i386 /usr/local/bin/kindlegen -c2 ${htmfile}.html ;;
esac

# create package
7z a ${htmfile}-HTML.7z *.html *.css ${htmfile}.opf
7z a -mx0 ${htmfile}-HTML.7z *.jpg *.png images/*.png images/*.jpg images/*.gif
7z a ${htmfile}-TEST.7z ${htmfile}.links.txt
7z x -y jpg.7z && rm jpg.7z 
export MYVERSION=`cat version.tex | cut -d '{' -f 3 | cut -d } -f 1`
export DATE=`date +%Y%m%d-%H%M%S`
export FOLDER=${MYVERSION}\(${DATE}\)
export FULLFOLDER="${HOME}/ebook/${htmfile}/${FOLDER}"
mkdir -p $FULLFOLDER
cp -v ${htmfile}.mobi ${htmfile}.epub "${pdffile}.pdf" ${htmfile}-HTML.7z ${htmfile}-TEST.7z $FULLFOLDER
