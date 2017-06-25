//fliler window size
#define WIN 7

#define ALGORITHM_OPTIMIZE

#define MORE_CALUCATION // ADD more calucation in the kernel
#ifdef MORE_CALUCATION
#define COUNT 50
int more_calc(int current,
              int sum,
              int cnt,
              int sign,
              int surround)
{
        int i;
        int cur = 0, result = 0;
        int flags[1000];
        // calculate flags
        for(i = 0; i < COUNT; i++)
        {
            flags[i] = (((i+1)% 113) * (i+3)) / (i+1) ;
        }

        for(i = 0; i < COUNT; i++)
        {
            cur = (current % sum) + flags[i];
            if (cur > flags[i])
                cur = (sign * surround * sum) / cur;
            else
                cur = (sign + surround + sum) / cur;
            result += (result % flags[i]);
        }

        return result;
}
#endif

#ifdef ALGORITHM_OPTIMIZE
__kernel void filter_nr(__global const uchar* input,
                        __global uchar* output,
                        int width,
                        int height,
                        int threshold)
{
    unsigned int localId = get_local_id(0);
    unsigned int globalId = get_global_id(0);
    unsigned int groupId = get_group_id(0);
    unsigned int loacalSize = get_local_size(0);
    int i, j, k;

    //current work item start position
    int pos = groupId * loacalSize + localId;
    int win = WIN / 2;
    int sum, cnt, sign;
    int current, surround;

    // calculate a column as a work item
    for(i = 0; i < height; i++)
    {
        sum = 0;
        cnt = 0;
        // coordinate: x = pos; y = i
        if(pos < win || i < win || pos >= width - win || i >= height - win)
        {
            output[i * width + pos] = input[i * width + pos];
        }
        else
        {
            current = (int)input[i * width + pos];
            for (j = -win; j <= win; j++)
            {
                //for (k = -win; k <= win; k++)
                {
                   surround = (int)input[(i + j) * width + pos - 3];
                   sign = (abs(surround - current) - threshold) >> 31;
                   sum += sign * surround;
                   cnt += sign;

                   surround = (int)input[(i + j) * width + pos - 2];
                   sign = (abs(surround - current) - threshold) >> 31;
                   sum += sign * surround;
                   cnt += sign;

                   surround = (int)input[(i + j) * width + pos - 1];
                   sign = (abs(surround - current) - threshold) >> 31;
                   sum += sign * surround;
                   cnt += sign;

                   surround = (int)input[(i + j) * width + pos];
                   sign = (abs(surround - current) - threshold) >> 31;
                   sum += sign * surround;
                   cnt += sign;

                   surround = (int)input[(i + j) * width + pos + 1];
                   sign = (abs(surround - current) - threshold) >> 31;
                   sum += sign * surround;
                   cnt += sign;

                   surround = (int)input[(i + j) * width + pos + 2];
                   sign = (abs(surround - current) - threshold) >> 31;
                   sum += sign * surround;
                   cnt += sign;

                   surround = (int)input[(i + j) * width + pos + 3];
                   sign = (abs(surround - current) - threshold) >> 31;
                   sum += sign * surround;
                   cnt += sign;

#ifdef MORE_CALUCATION
                   sum += more_calc(current, sum, cnt, sign, surround);
#endif
                }
            }
            output[i * width + pos] = sum / cnt;
        }
    }
}
#else
__kernel void filter_nr(__global const uchar* input,
                        __global uchar* output,
                        int width,
                        int height,
                        int threshold)
{
    unsigned int localId = get_local_id(0);
    unsigned int globalId = get_global_id(0);
    unsigned int groupId = get_group_id(0);
    unsigned int loacalSize = get_local_size(0);
    int i, j, k;

    //current work item start position
    int pos = groupId * loacalSize + localId;
    int win = WIN / 2;
    int sum, cnt, delta;

    // calculate a column as a work item
    for(i = 0; i < height; i++)
    {
        sum = 0;
        cnt = 0;

        // coordinate: x = pos; y = i
        if(pos < win || i < win || pos >= width - win || i >= height - win)
        {
            output[i * width + pos] = input[i * width + pos];
        }
        else
        {
            for (j = -win; j <= win; j++)
            {
                for (k = -win; k <= win; k++)
                {
                   delta = input[(i + j) * width + pos + k] - input[i * width + pos];
                   if (abs(delta) < threshold)
                   {
                       sum += input[(i + j) * width + pos + k];
                       cnt ++;
                   }
                }
            }
            output[i * width + pos] = sum / cnt;
        }
    }
}
#endif



