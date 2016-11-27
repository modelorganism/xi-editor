extern crate regex;

//use regex; //::{quote,RegexBuilder,Regex};
use xi_rope::rope::Rope;
use xi_rope::spans::{Spans,SpansBuilder};
use xi_rope::interval::Interval;

const REGEX: u64 = 1;
const CASE_SENSITIVE: u64 = 2;
const WHOLE_WORDS: u64 = 4;

#[derive(Copy, Clone)]
pub struct SearchOpts {
    is_grep: bool,
    only_words: bool,
    case_sensitive: bool
}

impl SearchOpts {
    /// Read the flags.
    pub fn from_flags(flags: u64) -> SearchOpts {
        SearchOpts{
            is_grep: REGEX&flags!=0,
            only_words: WHOLE_WORDS&flags!=0,
            case_sensitive: CASE_SENSITIVE&flags!=0
        }
    }
}

fn search_aux1(re: &regex::Regex,  text: &Rope, start: usize, end: usize )
                    -> Option<(usize,usize)> {
    let mut curr_loc = start;
    // Look for the search pattern in the text of each line.
    // XXX Dose not find matches that span lines.
    for line in text.lines(start, end) {
        match re.find(&line)  {
            Some((match_off, match_end_off)) => {
                return Some((curr_loc+match_off,curr_loc+match_end_off))
            },
            None => {
                curr_loc += line.len()+1
            }
        }
    };
    None
}

pub fn search_all(s: &Search, text: &Rope)
                    -> Spans<()> {

    let re = &s.item;
    let mut curr_loc = 0;
    // Look for the search pattern in the text of each line.
    // XXX Dose not find matches that span lines.
    let mut sb = SpansBuilder::new(15);

    for line in text.lines(0, text.len()) {
        for (match_off, match_end_off) in re.find_iter(&line) {
            sb.add_span(Interval::new_closed_open(curr_loc+match_off, curr_loc+match_end_off), () );
        }
        curr_loc += line.len() + 1;
    };
    sb.build()
}

pub struct Search {
    item:  regex::Regex
}


pub struct SearchState {
    item: Option<Result<regex::Regex, regex::Error>>,
    opts: SearchOpts,
}

impl SearchState {
    pub fn new() -> SearchState {
        SearchState{
            item: None,
            opts: SearchOpts::from_flags(0u64),
         }
    }

    pub fn from_str_and_opts(find_str: &str,
                             opt: SearchOpts)
                             -> SearchState {
        let re = if find_str.is_empty() {
            None
        }
        else {
            Some(build_regex(find_str, opt))
        };
        SearchState { item: re, opts:opt }
    }

    pub fn is_err(&self) -> bool {
        match self.item {
            Some(Err(_)) => true,
            _ => false
        }
    }

    pub fn maybe_search(&self) -> Option<Search> {

        match self.item  {
            Some(Ok(ref r)) => Some(Search{item:r.clone()}),
            _ => None
        }
    }
}

fn build_regex(find_str1: &str,
               opt: SearchOpts )
               -> Result<regex::Regex, regex::Error> {
    // Build the Regex, possibly modifying the search string along the way.
    let qstr : String;

    let str2 = if opt.is_grep {
       find_str1
    }
    else {
       qstr = regex::quote(find_str1);
       &qstr
    };

    let wstr : String;
    let str3 = if opt.only_words {
       wstr = format!(r#"\b{}\b"#, str2);
       &wstr
    }
    else {
       str2
    };

    let rb = regex::RegexBuilder::new(str3)
               .case_insensitive(!opt.case_sensitive);

    rb.compile()

}


/// Find first match between `start` & `end` in `text`.
pub fn search_1(find_str1: &str, flags:u64, text: &Rope, start: usize, end: usize )
                    -> Option<(usize,usize)> {

    print_err!("search grep: {} {}", find_str1, flags);

    if find_str1.is_empty() {
        return None;
    }
    let opt = SearchOpts::from_flags(flags);

    let re_res = build_regex(find_str1, opt);

    match re_res {
        Ok(re) => search_aux1(&re, text, start, end),
        Err(_) => None
    }
}
