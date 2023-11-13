# Search-for-Dates
This Perl script finds and recognizes dates in filenames and puts the date in the correct date format into the collectors table.

After you had created a list of your collections (a list of filenames and paths with fingerprints) by using our script list-all-files (see separate repo in the same Github-account), you can apply this script to add a date column to the list.

The script looks for any version of a date in the filename and converts it to a standard-date:

i.e what can be found and successfully processed, when such a string is somewhere in the filename (not necessary at the beginning):
  
    • "yyyymmdd" as in 20191224 for x-mas or
    • "ddmmyyyy" i.e. 24122019
    • "ddmmyy" i.e. 241219
    • "yymmdd" i.e. 191224
    • "yymmCdd" i.e. 1912C24 – the C is a constant, always just the letter C
    • "dd.mm.yyyy" as above, now with . or . & whitespace
    • "dd.mm.yy"
    • 2 dec 77
    • 77 dec 2
    • 4. Juli 33
    • 88 March 3
    • March, 3 1988
    • 72, 3. mar
    • 7205xx for 1. may 1972
    • 720500 for 1. may 1972
    • 7205?? for 1. may 1972
    • xx0571 for 1. may 1972
    • 000572 for 1. may 1972
    • 1st May 72
    • 3rd June 74
    • May 2nd 75
    • 10th of May 78
    • 23rd Dec 77
    
I have presented my solution for huge file collections and the confusion created by exchange among collectors here in two videos in 2019. In 2023 I have created subtitles and proofread them, to handle my bad pronounciation and to be able to translate these to German and Russian (switch on and choose in Youtube your language):

https://youtu.be/ptoGAqYE5OM?si=JBfOjvmHDc1cX48N

https://youtu.be/4SfnASlwBmk?si=TwT4-Y-H2A_KjkAR
