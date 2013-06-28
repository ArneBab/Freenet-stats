date

JAVA="java"
WGET="/usr/bin/wget --timeout=100"
BUNZIP2="/bin/bunzip2"
RUBY="/usr/bin/ruby1.9.3"
GNUPLOT="/usr/bin/gnuplot"
HOST="10.0.0.13:8888"
PARAMS="type=text/plain&max-size=999999999&forcedownload=true"

# toad test 1 - start at: 1:00 GMT+0
$WGET "http://amphibian.dyndns.org/freenet/tests/long-term-manysingleblocks/toad-long-term-manysingleblocks-test-2/anon-output.csv.bz2" -O 1.csv.bz2 || exit 1
$BUNZIP2 1.csv.bz2 -c >> data.csv

# toad test 2 - start at: starts right after test1
$WGET "http://amphibian.dyndns.org/freenet/tests/long-term-manysingleblocks/toad-long-term-manysingleblocks-test-1847656128/anon-output.csv.bz2" -O 2.csv.bz2 || exit 1
$BUNZIP2 2.csv.bz2 -c >> data.csv

# nextgen test 1 - start at: 1:00 GMT+0
$WGET "http://$HOST/freenet:USK@ZdHJo2kxmE4FXm1fFonEHCVJXxINyWWKqha8Wbpdvew,YxFNBQNWKNesExEkEob~hwroHGO8a7E1PUyfLj61lr0,AQACAAE/data.csv/-105?$PARAMS" -O 3.csv
cat 3.csv >> data.csv

# nextgen test 2 - start at: 6:00 GMT+0
$WGET "http://$HOST/freenet:USK@ZOpRGobWTDjjl8IKASQ2h3F-AXpYIm2rfFKT5TtPxw4,KqKUQyOiHl4JjUKhdymxE9kkuq5JUWZ9P5GgZSM1X7U,AQACAAE/data.csv/-105?$PARAMS" -O 4.csv
cat 4.csv >> data.csv

#John Doe test 1 - start at: 18:00 UTC
$WGET "http://$HOST/freenet:USK@BnMShqUABiJBTJqJ2evCdG9gSloP4IhikZyqYMK8pdo,zVcjbxbfFFYmYuRh6m1q2XQDy99biZGebH0EYp~qV8o,AQACAAE/data/-64/?$PARAMS" -O 5.csv
cat 5.csv >> data.csv

#Bombe test 1 - start at: 04:30 CET (GMT+1)
$WGET "http://$HOST/freenet:USK@3AE0ijTw4oA4hsttms0Sh46fGkliMHp~nstiMHSbAnM,alhhS5Y0UlDzuFraWmWOK95ipZKBJ35tdU76XkCIXgo,AQACAAE/ltmsbt/-96/many-single-blocks-test-Bombe.csv?$PARAMS" -O 6.csv
cat 6.csv >> data.csv

#Bombe test 2 - new data, start at: UNKNOWN
$WGET "http://$HOST/freenet:USK@GiTTxl6hVZYpwtqefzgB8mVnQ2GiZYHc5JCkCOjfRow,KlzBQYMkMUOqCmECoAPZHdccnCS36rttqNxGwfQ~~qc,AQACAAE/ltmsbt/-1/?$PARAMS" -O 7.csv
cat 7.csv >> data.csv

# FMS OO test1 - start at: 15:30 UTC
$WGET "http://$HOST/freenet:USK@KAj1tYINJWsmKLT1zubtabyX78ATEvT0M7ba9qCQu50,gha8s6LJE9gDMfRp-Js5eniPpK8Tt1BQzkNJJGhkKEM,AQACAAE/freenet_daily_stats_oo/-15/?$PARAMS" -O 8.csv
cat 8.csv >> data.csv

# Thomas - start at 04:00 CET
#cp ~/freenet/freenet/many-single-blocks-test-TESTING-LOCAL.csv 9.csv
#cat 9.csv >> data.csv

date

$RUBY preprocess.rb || exit 1

(cd ~/checkouts/fred/ && git pull origin master)
$RUBY group_versions.rb > group.csv 

#update the version distribution stats
cd version_distribution && ruby generate_gnuplot.rb && cd .. || exit 1
cd announcements && ruby generate_summary.rb && cd .. || exit 1
cd bootstrapping && ruby bootstrapping.rb && cd .. || exit 1


Rscript -e 'library(knitr); knit2html("index.Rmd", options=c("use_xhtml","smartypants","highlight_code"))'

rm *.csv
rm *.bz2

echo "STARTING INSERT"
date

$JAVA -cp ../jSite-0.11.1.jar de.todesbaum.jsite.main.CLI --project=Freenet_fetch_pull_stats

date
