
#include <assert.h>
#include <string>
#include "TChain.h"
#include "TFile.h"
#include "TObjArray.h"
#include "TTree.h"
//#include "../Tools/goodrun.cc"

#include "../CORE/CMS2.cc"


#include "Rtypes.h"
typedef ULong64_t uint64;

using namespace tas;

// Used to filter an ntuple based on the 'select' function return
// infile is the path to the ntuple you want to filter (* allowed)
// outfile is the result
// cut is specified in the select() function

// eg:
// ntupleFilter("/data/tmp/cms2-V03-00-10/MinimumBias_BeamCommissioning09-rereco_FIRSTCOLL_v1/*.root","/data/tmp/wandrews/minbias/filtered_ntuple.root")
//infile and outfile must end in ".root"

// WARNING: all of the input files are put into 1 output file, so
// please be careful you don't create a file which is enormous (unless
// you can handle enormous files)

bool select (bool isData)
{

  //if (isData) {
  //     if( !goodrun( evt_run(), evt_lumiBlock() ) ) return false;
  // }

    // loop on hyps
    for (size_t i = 0; i < cms2.hyp_type().size(); ++i) {
      LorentzVector lt_p4  = hyp_lt_p4()[i];
      LorentzVector ll_p4  = hyp_ll_p4()[i];
      if((TMath::Max(lt_p4.Pt(),ll_p4.Pt()) > 20 ) && (TMath::Min(lt_p4.Pt(),ll_p4.Pt()) > 10))
	return true;
    }

    return false;

}

void ntupleFilterTagAndProbe (const std::string &infile, const std::string &outfile, bool printPass=false, bool isData = true, std::string runlist = "")  
{
    // set good run list
    //if (runlist != "") set_goodrun_file(runlist.c_str());

    // output file and tree
    TFile *output =TFile::Open(outfile.c_str(), "RECREATE");
    assert(output != 0);
    TTree *newtree = 0;

    const long long max_tree_size = 20000000000000000LL;
    TTree::SetMaxTreeSize(max_tree_size);

    FILE *log = 0; //for keeping any output desired on selection
    if( printPass ) {
        size_t pos = outfile.find(".root");
        assert( pos != string::npos );
        std::string outcpy = outfile;
        log = fopen( outcpy.replace(pos, 5, "_run_lumi_event").c_str(), "w" );
    }

    TChain *chain = new TChain("Events");
    chain->Add(infile.c_str());
    TObjArray *listOfFiles = chain->GetListOfFiles();
    const uint64 nEventsChain = chain->GetEntries();
    uint64 nEventsTotal = 0;
    uint64 nEventsSelected = 0;

    // file loop
    TIter fileIter(listOfFiles);
    TFile *currentFile = 0;
    bool first = true;
    int i_permille_old = 0;
    while ( (currentFile = (TFile*)fileIter.Next()) ) {
        TFile f(currentFile->GetTitle());
        //const char *name = f.GetName();
        TTree *tree = (TTree*)f.Get("Events");

        //chain->SetBranchStatus(chain->GetAlias("evt_scale1fb"     ), 0);
        //chain->SetBranchStatus(chain->GetAlias("evt_xsec_excl"    ), 0);
        //chain->SetBranchStatus(chain->GetAlias("evt_xsec_incl"    ), 0);
        //chain->SetBranchStatus(chain->GetAlias("evt_kfactor"      ), 0);
        //chain->SetBranchStatus(chain->GetAlias("evt_nEvts"        ), 0);
        //chain->SetBranchStatus(chain->GetAlias("evt_filt_eff"     ), 0);
        chain->SetBranchStatus("EventAuxiliary",0);
        // for the first file, clone the tree
        if ( first ) {
            newtree = chain->CloneTree(0);
            newtree->SetDirectory(output);
            first = false;

        }

        // init
        cms2.Init(newtree);
        cms2.Init(tree);


        // Event Loop
        const unsigned int nEvents = tree->GetEntries();
        for (unsigned int event = 0; event < nEvents; ++event, ++nEventsTotal) {
            int i_permille = (int)floor(10000 * nEventsTotal / float(nEventsChain));
            if (i_permille != i_permille_old) {
                // xterm magic from L. Vacavant and A. Cerri
                if (isatty(1)) {
                    printf("\015\033[32m ---> \033[1m\033[31m%5.2f%%"
                            "\033[0m\033[32m <---\033[0m\015", i_permille/100.);
                    fflush(stdout);
                }
                i_permille_old = i_permille;
            }

            cms2.GetEntry(event);
            //set condition to skip event
            if (not select(isData)) 
                continue;

            ++nEventsSelected;
            if( printPass ) {
                fprintf(log, "%i %i %i\n", cms2.evt_run(), cms2.evt_lumiBlock(), cms2.evt_event() );
            }

            cms2.LoadAllBranches();

            // fill the new tree
            newtree->Fill();
        }
    }

    if( printPass ) {
        fprintf(log, "\nTotal events run on: %llu\n", nEventsTotal);
        fprintf(log, "Num events selected: %llu\n", nEventsSelected ); //need two fprintf statements bc of some gcc bug
    }

    output->cd();
    newtree->Write();
    delete output;
}

