/* Offline checks: policy reaches fresh request workspaces and prompts. */
#include <assert.h>
#include "../assistant.c"
int browsered_fetch_sources(const char *t,size_t n,const char *d,char *out,size_t size)
{ (void)t;(void)n;(void)d;if(size)out[0]=0;return 0; }
int main(void)
{
    assert(strstr(instructions,"NO Browsered rule prohibiting tools"));
    assert(!strstr(instructions,"do not run commands or use other tools"));
    struct Workspace w;
    assert(create_workspace(&w));
    const char *names[]={"AGENTS.md","CLAUDE.md"};
    for(size_t i=0;i<2;i++){
        char path[PATH_MAX];snprintf(path,sizeof(path),"%s/%s",w.root,names[i]);
        char *text=read_answer(path);assert(text);
        assert(strcmp(text,BROWSERED_USER_TOOL_POLICY)==0);free(text);
    }
    const char *parts[]={instructions,NULL};
    assert(write_prompt(w.prompt,parts,"Read the user-named file.",strlen("Read the user-named file.")));
    char *text=read_answer(w.prompt);assert(text);
    assert(strncmp(text,BROWSERED_USER_TOOL_POLICY,strlen(BROWSERED_USER_TOOL_POLICY))==0);
    free(text);remove_workspace(&w);
    puts("PASS: fresh AGENTS.md/CLAUDE.md and every-request tool policy");
    return 0;
}
