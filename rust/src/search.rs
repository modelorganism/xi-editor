extern crate regex;

use xi_rope::rope::Rope;
use xi_rope::spans::{Spans,SpansBuilder};
use xi_rope::interval::Interval;

const HARD_UPDATE: u64 = 1; // Immediately select the first occurance.
const SHOW_HITS: u64 = 2; //

const CASE_SENSITIVE: u64 = 16;
const WHOLE_WORDS: u64 = 8;

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
            is_grep: false,
            only_words: WHOLE_WORDS&flags!=0,
            case_sensitive: CASE_SENSITIVE&flags!=0
        }
    }
}

/// Remember the search, including whether or not we are looking for anything.
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

    /// Construct from the string and flags sent from the font end,. Empty string means don't search.
    pub fn from_str_and_flags(find_str: &str, flags: u64) -> (SearchState, bool, bool) {
        (SearchState::from_str_and_opts(find_str, SearchOpts::from_flags(flags)),
                                        flags&HARD_UPDATE!=0, flags&SHOW_HITS!=0)
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
    /// Is the grep erronious? Non-grep search strings are jsut thing to look for, so they are never wrong.
    pub fn is_err(&self) -> bool {
        match self.item {
            Some(Err(_)) => true,
            _ => false
        }
    }

    /// Return a search if search is called for. That is non-empty non-grep error.
    pub fn maybe_search(&self) -> Option<Search> {

        match self.item  {
            Some(Ok(ref r)) => Some(Search{item:r.clone()}),
            _ => None
        }
    }
}

// A Search that could be done on a Rope. A pattern essentially.
pub struct Search {
    item:  regex::Regex
}

impl Search {

    pub fn search_all(&self, text: &Rope) -> Spans<()> {

        let re = &self.item;
        let mut curr_loc = 0;
        // Look for the search pattern in the text of each line.
        // XXX Dose not find matches that span lines.
        let mut sb = SpansBuilder::new(text.len());

        for line in text.lines(0, text.len()) {
            for (match_off, match_end_off) in re.find_iter(&line) {
                sb.add_span(Interval::new_closed_open(curr_loc+match_off, curr_loc+match_end_off), () );
            }
            curr_loc += line.len() + 1;
        };
        sb.build()
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
