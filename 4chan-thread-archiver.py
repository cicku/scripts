#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

# BA 4chan-thread-archiver
#
# Built for the Bibliotheca Anonoma by Lawrence Wu, 2012/04/04
# Rewritten from scratch to use py4chan API wrapper, save in seperate images folder, download plain HTML, modularization, comments, and code cleanup
# Formerly based on https://github.com/socketubs/4chandownloader

#
# Initial release Nov. 5, 2009
# v6 release Jan. 20, 2009
# http://cal.freeshell.org
#
# Refactor, update and Python package
# by Socketubs (http://socketubs.net/)
# 09-08-12
#

import errno
import fileinput
import json
import time
import re
import os

import requests
import py4chan

"""=== Docopt Arguments and Documentation ==="""

from docopt import docopt

doc = """BA-4chan-thread-archiver. Uses the 4chan API (with the py4chan wrapper) 
to download thread images and/or thumbnails, along with thread HTML, JSON,
and a list of referenced external links.

Usage:
  4chan-thread-archiver <url> [--path=<string>] [--runonce] [--silent] [--delay=<int>] [--nothumbs] [--thumbsonly] [--enablessl]
  4chan-thread-archiver -h | --help
  4chan-thread-archiver -v | --version

Options:
  --path=<string>               Path to folder where archives will be saved
  --runonce                     Downloads the thread as it is presently, then exits
  --delay=<int>                 Delay between thread checks [default: 20]
  --nothumbs                    Don't download thumbnails
  --thumbsonly                  Download thumbnails, no images
  --enablessl                   Download using HTTPS
  -h --help                     Show help
  -v --version                  Show version
"""
# future options (need to implement later)
#--silent                      Suppresses mundane printouts, prints what's important

"""=== 4chan URL Settings ==="""

""" 4chan top level domain names """
FOURCHAN_BOARDS = 'boards.4chan.org'
FOURCHAN_CDN = '4cdn.org'

"""
    4chan Content Delivery Network domain names
    (for images, thumbs, api)
"""
FOURCHAN_API = 'a.' + FOURCHAN_CDN
FOURCHAN_IMAGES = 'i.' + FOURCHAN_CDN
FOURCHAN_THUMBS = 't.' + FOURCHAN_CDN
FOURCHAN_STATIC = 's.' + FOURCHAN_CDN

"""
    Retrieval Footer Regex
    Format is (boards, object_id)
"""
FOURCHAN_BOARDS_FOOTER = '/%s/thread/%s'
FOURCHAN_API_FOOTER = FOURCHAN_BOARDS_FOOTER + '.json'
FOURCHAN_IMAGES_FOOTER = '/%s/%s'
FOURCHAN_THUMBS_FOOTER = '/%s/%s'

"""
    Full HTTP Links to 4chan servers, without HTTP headers
    Used for creating download links.
"""
FOURCHAN_BOARDS_URL = FOURCHAN_BOARDS + FOURCHAN_BOARDS_FOOTER
FOURCHAN_API_URL = FOURCHAN_API + FOURCHAN_API_FOOTER
FOURCHAN_IMAGES_URL = FOURCHAN_IMAGES + FOURCHAN_IMAGES_FOOTER
FOURCHAN_THUMBS_URL = FOURCHAN_THUMBS + FOURCHAN_THUMBS_FOOTER

"""
    HTML Parsing Regex
    Matches links in dumped HTML.
"""
HTTP_HEADER_UNIV = r"https?://"          # works for both http and https links
FOURCHAN_IMAGES_REGEX = r"/\w+/"
FOURCHAN_THUMBS_REGEX = r"/\w+/"
FOURCHAN_CSS_REGEX = r"/css/(\w+)\.\d+.css"

"""
    Regex Links to 4chan servers, without HTTP headers
    Used to match and replace links in dumped HTML.
"""

FOURCHAN_IMAGES_URL_REGEX = re.compile(HTTP_HEADER_UNIV + FOURCHAN_IMAGES + FOURCHAN_IMAGES_REGEX)
FOURCHAN_THUMBS_URL_REGEX = re.compile(HTTP_HEADER_UNIV + "\d+." + FOURCHAN_THUMBS + FOURCHAN_THUMBS_REGEX)

"""=== Folder Structure Settings ==="""

""" default folder names for image and thumbnails """
_DEFAULT_FOLDER = "4chan"
_IMAGE_DIR_NAME = "images"
_THUMB_DIR_NAME = "thumbs"
_CSS_DIR_NAME = "css"

""" external link filename """
EXT_LINKS_FILENAME = "external_links.txt"

"""
    The Ultimate URL Regex
    <http://stackoverflow.com/questions/520031/whats-the-cleanest-way-to-extract-urls-from-a-string-using-python>
"""
URLREGEX = re.compile(r"""((?:[a-z][\w-]+:(?:/{1,3}|[a-z0-9%])|www\d{0,3}[.]|[a-z0-9.\-]+[.‌​][a-z]{2,4}/)(?:[^\s()<>]+|(([^\s()<>]+|(([^\s()<>]+)))*))+(?:(([^\s()<>]+|(‌​([^\s()<>]+)))*)|[^\s`!()[]{};:'".,<>?«»“”‘’]))""", re.DOTALL)

""" Important Message Front Tag """
_TAG = " :: "


"""=== Utilities ==="""

def make_sure_path_exists(path):
    """
        Recursively create folder paths if they don't exist 
        (update) with `os.makedirs(path,exist_ok=True)` in python3

        :param path: os.path object to file
    """
    try:
      os.makedirs(path)

    except OSError as exception:
      if exception.errno != errno.EEXIST:
        raise



def download_file(fname, dst_folder, file_url, overwrite=False):
    """
        Download any file using requests, in chunks.

        :param fname: filename string
        :param dst_folder: output folder string
        :param file_url: url to download from, string
        :param overwrite: Overwrite any existing files, bool
    """
    # Destination of downloaded file
    file_dst = os.path.join(dst_folder, fname)

    # If the file doesn't exist, download it
    if ( not os.path.exists(file_dst) ) or overwrite:
      print(_TAG + '%s downloading...' % fname)
      i = requests.get(file_url)

      if i.status_code == 404:
        print(_TAG + 'Failed, try later (%s)' % file_url)
      else:
        # download file in chunks of 1KB
        with open(file_dst, 'wb') as fd:
          for chunk in i.iter_content(chunk_size=1024):
            fd.write(chunk)

    else:
      print(_TAG + '%s already downloaded' % fname)



def download_json(json_url, fname, dst_dir):
    """
        Download JSON to local file, pretty printed

        :param json_url: string, URL to download from
        :param fname: string, destination filename, no extension
        :param dst_dir: string, destination folder
    """
    json_filename = "%s.json" % fname
    json_path = os.path.join(dst_dir, json_filename)
    print(_TAG + "Downloading %s..." % json_filename)

    json_thread = requests.get(json_url)
    json.dump(json_thread.json(), open(json_path, 'w'), sort_keys=True, indent=2, separators=(',', ': '))



def file_replace(fname, pat, s_after):
    """
        File in place regex function, using fileinput
        Notice: all parameters are recommended to be in r"raw strings"

        :param fname: filename string
        :param pat: regex pattern to search for, as a string
        :param s_after: what to replace pattern in file with, string
    """

    for line in fileinput.input(fname, inplace=True):
      print(re.sub(pat, s_after, line))



"""=== Dump Functions ==="""

def dump_json(dst_dir, board, thread, https=False):
    """
        Dump 4chan JSON to local file, pretty printed

        :param dst_dir: string, destination folder
        :param board: string, board name
        :param thread: string, thread id
        :param https: bool, download using https. Default value: False
    """
    http_header = ('http://' if not https else 'https://')
    json_url = http_header + FOURCHAN_API_URL % (board, thread)
    download_json(json_url, thread, dst_dir)

def dump_css(dst_dir, https=True):
    """
        Dumps the CSS from 4cdn.
        (FIXME) Currently uses a static list of links, which works but is not ideal.
        Eventually, we need to create a JSON HTML Templater system.

        :param dst_dir: string, destination folder
        :param https: bool, download using https. Default value: False
    """
    fourchan_css_url_regex = re.compile(HTTP_HEADER_UNIV + FOURCHAN_STATIC + FOURCHAN_CSS_REGEX)
    http_header = ('http://' if not https else 'https://')

    # (FUTURE) Mod dump_css() to automatically scrape CSS links each time.
    css_list = [http_header + FOURCHAN_STATIC + "/css/yotsubluemobile.473.css",
    http_header + FOURCHAN_STATIC + "/css/yotsubluenew.473.css", 
    http_header + FOURCHAN_STATIC + "/css/yotsubanew.473.css", 
    http_header + FOURCHAN_STATIC + "/css/futabanew.473.css", 
    http_header + FOURCHAN_STATIC + "/css/burichannew.473.css", 
    http_header + FOURCHAN_STATIC + "/css/photon.473.css",
    http_header + FOURCHAN_STATIC + "/css/tomorrow.473.css"]

    for css_url in css_list:
      css_name = re.sub(fourchan_css_url_regex, r"\1.css", css_url)
      download_file(css_name, dst_dir, css_url)



def dump_html(dst_dir, board, thread, https=False):
    """
        Dumps thread in raw HTML format to `<thread-id>.html`

        :param dst_dir: string, destination folder
        :param board: string, board name
        :param thread: string, thread id
        :param https: bool, download using https. Default value: False
    """
    html_filename = "%s.html" % thread
    http_header = ('http://' if not https else 'https://')
    html_url = http_header + FOURCHAN_BOARDS_URL % (board, thread)
    download_file(html_filename, dst_dir, html_url, overwrite=True)

    # Convert all links in HTML dump to use locally downloaded files
    html_path = os.path.join(dst_dir, html_filename)
    file_replace(html_path, '"//', '"' + http_header)
    file_replace(html_path, FOURCHAN_IMAGES_URL_REGEX, _IMAGE_DIR_NAME + "/")
    file_replace(html_path, FOURCHAN_THUMBS_URL_REGEX, _THUMB_DIR_NAME + "/")

    # Download a local copy of all CSS files
    dst_css_dir = os.path.join(dst_dir, _CSS_DIR_NAME)
    make_sure_path_exists(dst_css_dir)
    dump_css(dst_css_dir, https)

    # convert HTML links to use local CSS files that we just downloaded
    # (FIXME) Might want to mod the HTML to use only ONE CSS file (perhaps by option)
    file_replace(html_path, HTTP_HEADER_UNIV + FOURCHAN_STATIC + FOURCHAN_CSS_REGEX, _CSS_DIR_NAME + r"/\1.css")



def find_in_all_posts(curr_thread, regex, fname, dst_dir):
    """
        Find a regex pattern in all comments and record them in a file

        :param dst_dir: string, destination folder
        :param regex: re.compile() object pattern to look for
        :param fname: filename to write to
        :param curr_thread: py4chan Thread object
    """

    # File to store list of all external links quoted in comments (overwrite upon each loop iteration)
    listing_dst = os.path.join(dst_dir, fname)
    listing_file = open(listing_dst, "w")

    for reply in curr_thread.replies:
      if (reply.Comment == None):
        continue

      if not regex.search(reply.Comment):
        continue

      else:
        # We need to get rid of all <wbr> tags before parsing
        cleaned_com = re.sub(r'\<wbr\>', '', reply.Comment)
        listing = re.findall(regex, cleaned_com)
        for item in listing:
          print(_TAG + "Found URL, saving in %s:\n%s\n" % (listing_dst, item[0]))
          listing_file.write(item[0])	# re.findall creates tuple
          listing_file.write('\n')	# subdivide with newlines

    # Close listing file after loop
    listing_file.close()



def get_images(curr_thread, dst_dir):
    """
        Download all images

        :param curr_thread: py4chan Thread object
        :param dst_dir: string, destination folder
    """
    # Create and set destination folders
    dst_images_dir = os.path.join(dst_dir, _IMAGE_DIR_NAME)
    make_sure_path_exists(dst_images_dir)

    # Dump all images within a thread from 4chan
#    for image_url in curr_thread.image_urls():
    for image_url in curr_thread.Files():
      image_name = re.sub(FOURCHAN_IMAGES_URL_REGEX, '', image_url)
      download_file(image_name, dst_images_dir, image_url)

def get_thumbs(curr_thread, dst_dir):
    """
        Download all thumbnails

        :param curr_thread: py4chan Thread object
        :param dst_dir: string, destination folder
    """
    # Create and set destination folders
    dst_thumbs_dir = os.path.join(dst_dir, _THUMB_DIR_NAME)
    make_sure_path_exists(dst_thumbs_dir)

    # Dump all thumbnails within a thread from 4chan
#    for thumb_url in curr_thread.thumb_urls():
    for thumb_url in curr_thread.Thumbs():
      thumb_name = re.sub(FOURCHAN_THUMBS_URL_REGEX, '', thumb_url)
      download_file(thumb_name, dst_thumbs_dir, thumb_url)



def dump(dst_dir, board, thread, curr_thread, nothumbs=False, thumbsonly=False, https=False):
    """
        Dump the thread using the functions defined above

        :param dst_dir: string, destination folder
        :param board: string, board name
        :param thread: string, thread id
        :param curr_thread: py4chan Thread object
        :param nothumbs: bool, get thumbnails or not. Default value: False
        :param thumbsonly: bool, only get thumbnails. Default value: False
        :param https: bool, download using https. Default value: False
    """
    # Create paths if they don't exist
    make_sure_path_exists(dst_dir)

    # Choose whether to download images
    if (thumbsonly == False):
        get_images(curr_thread, dst_dir)

    # Choose whether to download thumbnails
    if (thumbsonly or (nothumbs == False)):
        get_thumbs(curr_thread, dst_dir)

    # Get all external links quoted in comments
    find_in_all_posts(curr_thread, URLREGEX, EXT_LINKS_FILENAME, dst_dir)

    # Dumps thread in raw HTML format to `<thread-id>.html`
    dump_html(dst_dir, board, thread, https)

    # Dumps thread in JSON format to `<thread-id>.json` file, pretty printed
    dump_json(dst_dir, board, thread, https)



"""=== Main Function ==="""

def check_url(url):
    """
        Make sure that the given URL is a valid 4chan thread URL.
        Originates from The Chandler by Dhole
    """
    url_parsed = re.findall("http(?:s)?://(?:boards.)?.*/*/(?:thread|res)?/[0-9]+(?:.php|.html)?", url)
    if len(url_parsed) < 1:
      return ""
    else:
      return url_parsed[0]

def timestamp():
    """
        `Timestamp` 
        <http://www.interfaceware.com/manual/timestamps_with_milliseconds.html>_

        :returns: string, timestamp
    """

    now = time.time()
    localtime = time.localtime(now)
    return time.strftime('%Y-%m-%d %H:%M:%S', localtime)



def main(args):
    """
        Check 4chan API for new content, and recursively dump thread
    """
    # Stop the script if the given URL is malformed
    if (check_url(args.get('<url>')) == ""):
      print(_TAG + "The URL is invalid, or it isn't a 4chan thread URL.")
      raise SystemExit(0)

    # Copy data from docopt arguments
    thread = args.get('<url>').split('/')[5]
    board  = args.get('<url>').split('/')[3]
    path   = args.get('--path')
    runonce = args.get('--runonce', False)
#    silent = args.get('--silent', False)       # must implement silent later
    delay  = args.get('--delay')
    nothumbs = args.get('--nothumbs', False)
    thumbsonly = args.get('--thumbsonly', False)
    enablessl = args.get('--enablessl', False)


    # Set a default path if none is given
    if (path == None):
      path = os.path.join(os.getcwd() + os.path.sep + _DEFAULT_FOLDER)

    # Set destination directory
    dst_dir = os.path.join(path, board, thread)


    # Initialize py4chan Board object, enable https
    curr_board = py4chan.Board(board, https=enablessl)


    # Check if the thread exists, then create py4chan thread object. Stop if not found
    try:
      if (curr_board.threadExists(int(thread))):
        curr_thread = curr_board.getThread(int(thread))
#      if (curr_board.thread_exists(int(thread))):
#        curr_thread = curr_board.get_thread(int(thread))       # BA py-4chan 0.3
      else:
        print(_TAG + "Thread %s not found." % thread)
        print(_TAG + "Either the thread already 404'ed, your URL is incorrect, or you aren't connected to the internet")
        raise SystemExit(0)
    # FIXME: Handles the error of no internet connection, but better to except requests.exceptions.ConnectionError:
    except:
        print(_TAG + "Unable to connect to the internet.")
        raise SystemExit(0)
        
    # header
    print(_TAG + 'Board : 4chan /%s/' % board)
    print(_TAG + 'Thread: %s' % thread)
    print(_TAG + 'Folder: %s' % dst_dir)


    # Using try/except loop to handle Ctrl-C
    try:
      # Switch to check for first run
      first_iteration = True

      running = True
      
      while running:
        # don't run this code the first time
        if (first_iteration == False):

          # Wait to execute code again
          print("\n" + _TAG + "Waiting %s seconds before retrying (Type Ctrl-C to stop)" % delay)
          time.sleep(int(delay))

          if curr_thread.is_404:
            # Stop when thread gets 404'ed
            print(_TAG + "%s - [Thread 404'ed or Connection Lost]" % timestamp())
            print(" :: Dump complete. To resume dumping the same thread,\nrun this script again.")
            raise SystemExit(0)
          
          
          # Update thread and check if new replies have appeared
          new_replies = curr_thread.update()
          if (new_replies == 0):
            print(_TAG + "%s - [No new posts.]" % timestamp())
            continue
          
          else:
              print(_TAG + "%s - [%s new post(s) found!]" % (timestamp(), new_replies))
          
          # If all tests are OK, dump thread again
          dump(dst_dir, board, thread, curr_thread, nothumbs, thumbsonly, https=enablessl)
          
          # If the 'runonce' flag is set, then end the loop and exit early
          if runonce: running = False
          
        else:
          # dump thread for the first time
          dump(dst_dir, board, thread, curr_thread, nothumbs, thumbsonly, https=enablessl)
          
          # first iteration is complete
          first_iteration = False

    except KeyboardInterrupt:
      """ Stop try/except loop when [Ctrl-C] is pressed"""
      print("\n")
      print(" :: Dump complete. To resume dumping the same thread,\nrun this script again.")
      raise SystemExit(0)



"""
    Use docopt to get arguments, and run main function
"""
if __name__ == '__main__':
  args = docopt(doc, version=0.3)
  main(args)
