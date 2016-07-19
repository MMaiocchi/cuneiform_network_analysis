#This script generates the network graphs published in M. Maiocchi 2016, Exploratory Analysis of Cuneriform Archives: a Network Approach to Ebla Texts, SMEA NS 2.
#This is a free, open source piece of software.
#Feel free to modify it and use it for your own research.
#If this script facilitates your scientific outcomes, please don't forget to quote the above mentioned article in your own publication.
#This might help the author to produce other useful open source scripts in the future.

use Unicode::Collate;
use utf8::all;

print "--- Cuneiform Network Generator ---\n";
print "Script by Massimo Maiocchi, 2016\n";
print "Generates network graphs (.gexf), as those published in M. Maiocchi 2016, Exploratory Analysis of Cuneriform Archives: a Network Approach to Ebla Texts, SMEA NS 2\n";
print "Assumes input_file.txt available in the same folder where this script resides\n";
print "Input file must contain encoded transliterations (UTF-8 supported) of cuneiform texts, with the following conventions:
- text headings are marked by \$ 
- personal names are marked by p_\n";
print "Ex.:
\$ T 09 0068
r.1.1 1 mi-at 50 gú-bar za-la-dum
r.1.2 ŠE-BA GURUŠ-GURUŠ
r.1.3 p_ha-ra-*NI
r.1.4 Ì-NA-SUM
";
print "\nTransliterations of Ebla texts are available on line through the Ebla Digital Archives project: http://ebla.isma.cnr.it\n"; 

open(IN, "<input_file.txt") || die "Error opening the text file: $!\n\n";
open(OUT, ">_TXT_graph.gexf") || die "Error creating the output file: $!\n\n";
open(OUT2, ">_PNS_graph.gexf") || die "Error creating the outptu file: $!\n\n";
open(W, ">warnings.txt") || die "Error creating the warnings file: $!\n\n";

@texts = <IN>;

$unwanted_characters = '(\"|\*|\?|\!|\(|\)|\[|\]|\{|\}|\<\<|\>\>|\<|\>|⸢|⸣)';



#gathering data
print "STEP1: gathering all text nos. and PNS\n";
for ($h=0;$h<=$#texts;$h++) {
    $line = $texts[$h];
    $next_line = $texts[$h+1];
    next if ($line =~ /^\$\$/);
    next if ($line =~ /^\$n/);
    next if ($line =~ /^\$b/);
    if ($line =~ /^\$\s?(.+)/) {
        $text_num = $1;
        $hash_texts{$text_num}++;
    }
    
    #remove square brackets and other unwanted characters
    $line =~ s/$unwanted_characters//g; 
    $next_line =~ s/$unwanted_characters//g; 

    $pn_in_line = "";
    if (($line =~ /(p_.+)/) && ($line)) { #this implies only one PN per line > note that PN followed by a title is considered different from PN without further indications
        $pn_in_line = $1;
        $pn_in_line =~ s/[a-zA-Z]_//g;  #strip EbDA encoding
        $pn_in_line =~ s/\s+$//; #remove possible empty spaces at the end of PN (typos)
        
        #ignore very broken PNs
        if ($pn_in_line =~ /…/) {
            print W "--- skipped PN: $pn_in_line\n";
            next;
        }
                
        $hash_PNs{$pn_in_line}{$text_num}++; #PN => Text_no => count
        $hash_PNs2{$pn_in_line}++; #reduntant but easier to implement > used for generating the PNs graph
    }
    
    ###Uncomment this section to add extra actors: kings and queens (en, en GN, ma-lik-tum, ma-lik-tum GN)
    #if (($line =~ /\d* EN\s*$/) && ($next_line !~ /g_/) && ($line)) {
    #    $pn_in_line = "EN";
    #    $hash_PNs{$pn_in_line}{$text_num}++; #PN => Text_no => count
    #    $hash_PNs2{$pn_in_line}++ #reduntant but easier to implement > used for generating the PNs graph
    #}
    #
    #if (($line =~ /\d* EN\s*$/) && ($next_line =~ /(g_.+)/) && ($line)) {        
    #    $GN = $1;
    #    $GN =~ s/[a-zA-Z]_//g;  #strip EbDA encoding
    #    $pn_in_line = "EN / ".$GN;
    #    print "-->$pn_in_line\n";
    #    $hash_PNs{$pn_in_line}{$text_num}++; #PN => Text_no => count
    #    $hash_PNs2{$pn_in_line}++ #reduntant but easier to implement > used for generating the PNs graph
    #}
    #
    #if (($line =~ /ma-lik-dum\s*/) && ($next_line !~ /g_/) && ($line)) {   
    #    $pn_in_line = "ma-lik-tum";
    #    $hash_PNs{$pn_in_line}{$text_num}++; #PN => Text_no => count
    #    $hash_PNs2{$pn_in_line}++ #reduntant but easier to implement > used for generating the PNs graph   
    #}
    #
    #if (($line =~ /ma-lik-dum\s*/) && ($next_line =~ /(g_.+)/) && ($line)) {   
    #    $GN = $1;
    #    $GN =~ s/[a-zA-Z]_//g;  #strip EbDA encoding
    #    $pn_in_line = "ma-lik-tum"." / ".$GN;
    #    print "-->$pn_in_line\n";
    #    $hash_PNs{$pn_in_line}{$text_num}++; #PN => Text_no => count
    #    $hash_PNs2{$pn_in_line}++ #reduntant but easier to implement > used for generating the PNs graph   
    #}
    
}

##### NETWORK MAP    ##############################################################
##### PART I (texts) ##############################################################
print OUT "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
print OUT "<gexf xmlns=\"http://www.gexf.net/1.2draft\"\n";
print OUT "    xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n";
print OUT "    xsi:schemaLocation=\"http://www.gexf.net/1.2draft http://www.gexf.net/1.2draft/gexf.xsd\"    version=\"1.2\">\n";
print OUT "    <graph mode=\"static\" defaultedgetype=\"undirected\">\n";
print OUT "         <attributes class=\"node\">\n";
print OUT "            <attribute id=\"0\" title=\"url\" type=\"string\"/>\n";
print OUT "         </attributes>\n\n";

print OUT "<nodes>\n";
foreach $text (keys %hash_texts) {
    #resolving URLS
    $url = "";
    $vol_num = "";
    $t_num = "";
    $letter = "";
    $series = "";
    #detecting texts heading
    if ($text =~ m/([A-Z]+)\s+(\d+)\s+(\d*)([A-Z]*)/) { #FORMAT MUST BE T 01 0001, MEE 12 0001, S 04 EA etc.
        $series = $1;
        $vol_num =  sprintf("%02d", $2); #change 1 -> 01
        $t_num = sprintf("%04d", $3); #change 1 -> 0001
        $letter = $4;
        $url =~ s/\s+//g;
        $url =  "http://virgo.unive.it/eblaonline/cgi-bin/tavoletta.cgi?id=".$series." ".$vol_num." ".$t_num.$letter;    
    }
    
    #print OUT "\t<node>\n";
    print OUT "\t<node id=\"$text\" label=\"$text\">\n";
    print OUT "\t\t<attvalues>\n";
    print OUT "\t\t\t<attvalue for=\"0\" value=\"$url\"/>\n";
    print OUT "\t\t</attvalues>\n";
    print OUT "\t</node>\n";

}

print OUT "</nodes>\n";
print OUT "<edges>\n";


print "STEP2: gathering unique PNS\n";
#gathering unique PNS
foreach $PN (keys %hash_PNs) {
    $array_PNs[$x] = $PN;
    $x++;
}

print "STEP3: linking texts\n";
@array_PNs = sort @array_PNs;
for ($k=0;$k<=$#array_PNs;$k++){
    $PN1 = $array_PNs[$k];                         #get a PN 
    @array_texts = sort keys (%{$hash_PNs{$PN1}}); #consider all texts in which that PN is mentioned #NB sort necessary otherwise random access to hash creates random couple T1-T2 or T2-T1 
    
    for ($a=0;$a<=$#array_texts-1;$a++) { #for each of those texts, except for the last one
        for ($b=$a+1;$b<=$#array_texts;$b++) { #for any other of those texts
            $couple = $array_texts[$a]."__".$array_texts[$b]; #creates a text couple T1__T2
            $couple_hash{$couple}++; #creates a hash of couples Tx__Ty => z (= number of PNs in common)
            $edge_PNs_hash{$couple}{$PN1}++; #creates a hash Tx__Ty => PN1 => 1
        }
    }
}
$edge_id = 0;

print "STEP4: printing graph - text network\n";
foreach $pair (keys %couple_hash) {
    @text_couple = split (/__/, $pair);
    $text1 = $text_couple[0];
    $text2 = $text_couple[1];
    $edge_weight = $couple_hash{$pair};    
    
    #Establishing edges labels as PNs linking the tablets
    @edge_label = "";
    @edge_PNs = keys (%{$edge_PNs_hash{$pair}});
    @edge_PNs = sort @edge_PNs;
    $edge_label = join (" - ", @edge_PNs);
    $edge_label =~ s/p_//g;
    
    print OUT "\t<edge id=\"$edge_id\" source=\"$text1\" target=\"$text2\" label=\"$edge_label\" weight=\"$edge_weight\"/>\n";
    $edge_id++;
}


print OUT "</edges>\n";
print OUT "</graph>\n";
print OUT "</gexf>\n";


##### NETWORK MAP   ##############################################################
##### PART II (PNs) ##############################################################

print OUT2 "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
print OUT2 "<gexf xmlns=\"http://www.gexf.net/1.2draft\"\n";
print OUT2 "    xmlns:viz=\"http://www.gexf.net/1.1draft/viz\"\n";
print OUT2 "    xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n";
print OUT2 "    xsi:schemaLocation=\"http://www.gexf.net/1.2draft http://www.gexf.net/1.2draft/gexf.xsd\"    version=\"1.2\">\n";
print OUT2 "    <graph mode=\"static\" defaultedgetype=\"undirected\">\n";
print OUT2 "         <attributes class=\"node\">\n";
print OUT2 "            <attribute id=\"0\" title=\"PN_frequency\" type=\"integer\"/>\n"; #information on PNs frequency is stored both as node attribute and using viz (see below)
print OUT2 "         </attributes>\n\n";

print OUT2 "<nodes>\n";

foreach $pn (keys %hash_PNs2) {
    
    $pn_frequency = $hash_PNs2{$pn};
    print OUT2 "\t<node id=\"$pn\" label=\"$pn\">\n";
    print OUT2 "<viz:size value=\"$pn_frequency\"/>";
    print OUT2 "\t\t<attvalues>\n";
    print OUT2 "\t\t\t<attvalue for=\"0\" value=\"$pn_frequency\"/>\n";
    print OUT2 "\t\t</attvalues>\n";
    print OUT2 "\t</node>\n";
    
}

print OUT2 "</nodes>\n";
print OUT2 "<edges>\n";


#This section is computationally demanding, due to the nested loop and array comparison.
print "generating PNs network\n"; 
$edge_id = 0;
@PN_list = sort keys (%hash_PNs);
$total_PNs = $#PN_list;
for ($n=0;$n<=$#PN_list;$n++) {
    @text_list1 = keys %{$hash_PNs{$PN_list[$n]}};
    @intersection = "";
    $number_of_texts_in_common = 0;
    for ($m=$n+1;$m<=$#PN_list;$m++) {
        @text_list2 = keys %{$hash_PNs{$PN_list[$m]}};
        $lc = List::Compare->new(\@text_list1, \@text_list2);
        @intersection = $lc->get_intersection;
        $number_of_texts_in_common = $#intersection + 1; #+1 is required since the first index of an array is 0
        if ($number_of_texts_in_common > 0) {
            print OUT2 "\t<edge id=\"$edge_id\" source=\"$PN_list[$n]\" target=\"$PN_list[$m]\" label=\"@intersection\" weight=\"$number_of_texts_in_common\"/>\n";
            $edge_id++;
        }
         
    }
    print "processing $n out of $total_PNs PNs\n"; 
}


print OUT2 "</edges>\n";
print OUT2 "</graph>\n";
print OUT2 "</gexf>\n";

print "\nFiles _TXT_graph.gexf and _PN_graph.gexf correctly generated in the current directory\n";

close IN;
close OUT;
close OUT2;
close W;